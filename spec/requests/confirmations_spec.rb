require "rails_helper"

RSpec.describe "Confirmations" do
  let(:user) { create(:user, :unconfirmed) }
  let(:token) { user.generate_token_for(:email_confirmation) }

  describe "GET /confirmations/:token" do
    it "confirms the account and opens a session" do
      get confirmation_path(token)

      expect(user.reload).to be_confirmed
      expect(response).to redirect_to(root_path)

      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "refuses a token that has expired" do
      expired = token

      travel 25.hours do
        get confirmation_path(expired)

        expect(user.reload).not_to be_confirmed
        expect(response).to redirect_to(new_confirmation_path)
      end
    end

    it "refuses a token that does not decode" do
      get confirmation_path("nao-e-um-token")

      expect(response).to redirect_to(new_confirmation_path)
    end

    it "leaves an already confirmed account untouched" do
      user.confirm!
      confirmed_at = user.reload.confirmed_at

      travel 1.hour do
        get confirmation_path(token)

        expect(user.reload.confirmed_at).to eq(confirmed_at)
      end
    end
  end

  describe "POST /confirmations" do
    it "sends a new link to an unconfirmed account" do
      expect { post confirmations_path, params: { email_address: user.email_address } }
        .to have_enqueued_mail(UserMailer, :confirmation)
    end

    it "sends nothing for an address with no account, answering the same way" do
      post confirmations_path, params: { email_address: user.email_address }
      known = [ response.status, response.location, flash.to_h ]

      expect { post confirmations_path, params: { email_address: "ninguem@exemplo.com" } }
        .not_to have_enqueued_mail(UserMailer, :confirmation)

      expect([ response.status, response.location, flash.to_h ]).to eq(known)
    end

    it "sends nothing to an account that is already confirmed" do
      confirmed = create(:user)

      expect { post confirmations_path, params: { email_address: confirmed.email_address } }
        .not_to have_enqueued_mail(UserMailer, :confirmation)
    end
  end
end
