require "rails_helper"

RSpec.describe "Registrations" do
  let(:allowed_address) { "maria@exemplo.com" }
  let(:params) do
    { user: { name: "Maria Silva", email_address: allowed_address, password: "segredo-muito-bom" } }
  end

  before { allow_signups_from(allowed_address) }

  describe "GET /registration/new" do
    it "is reachable without a session" do
      get new_registration_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /registration" do
    it "creates an unconfirmed account for an allowed address" do
      expect { post registration_path, params: }.to change(User, :count).by(1)

      user = User.find_by(email_address: allowed_address)
      expect(user.name).to eq("Maria Silva")
      expect(user).not_to be_confirmed
    end

    it "sends the confirmation email" do
      expect { post registration_path, params: }
        .to have_enqueued_mail(UserMailer, :confirmation)
    end

    it "does not open a session before the address is confirmed" do
      post registration_path, params: params
      get root_path
      expect(response).to redirect_to(new_session_path)
    end

    it "rejects a password below the minimum length" do
      params[:user][:password] = "curta"

      expect { post registration_path, params: }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    context "when the address is not on the allowlist" do
      let(:params) do
        { user: { name: "Intruso", email_address: "intruso@exemplo.com", password: "segredo-muito-bom" } }
      end

      it "creates no account and sends no email" do
        expect { post registration_path, params: }.not_to change(User, :count)
        expect { post registration_path, params: }.not_to have_enqueued_mail(UserMailer, :confirmation)
      end

      it "answers exactly as it does for an accepted registration" do
        post registration_path, params: params
        refused = [ response.status, response.location, flash.to_h ]

        post registration_path, params: { user: params[:user].merge(email_address: allowed_address) }
        accepted = [ response.status, response.location, flash.to_h ]

        expect(refused).to eq(accepted)
      end
    end

    context "when the address already has an account" do
      before { create(:user, email_address: allowed_address, name: "Dona da conta") }

      it "creates no second account and leaves the existing one untouched" do
        expect { post registration_path, params: }.not_to change(User, :count)
        expect(User.find_by(email_address: allowed_address).name).to eq("Dona da conta")
      end

      it "does not reveal that the address is taken" do
        post registration_path, params: params
        expect(response).to redirect_to(new_session_path)
        expect(flash.to_h.values.join).not_to match(/cadastrad|existe|taken/i)
      end
    end
  end
end
