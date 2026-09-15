require "rails_helper"

RSpec.describe "Passwords" do
  let(:old_password) { "senha-antiga-boa" }
  let(:new_password) { "senha-nova-melhor" }
  let(:user) { create(:user, password: old_password) }
  let(:token) { user.password_reset_token }

  describe "GET /passwords/new" do
    it "is reachable without a session" do
      get new_password_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /passwords" do
    it "sends the reset link to an existing account" do
      expect { post passwords_path, params: { email_address: user.email_address } }
        .to have_enqueued_mail(PasswordsMailer, :reset)
    end

    it "sends nothing for an unknown address, answering the same way" do
      post passwords_path, params: { email_address: user.email_address }
      known = [ response.status, response.location, flash.to_h ]

      expect { post passwords_path, params: { email_address: "ninguem@exemplo.com" } }
        .not_to have_enqueued_mail(PasswordsMailer, :reset)

      expect([ response.status, response.location, flash.to_h ]).to eq(known)
    end
  end

  describe "GET /passwords/:token/edit" do
    it "opens the form for a valid link" do
      get edit_password_path(token)

      expect(response).to have_http_status(:ok)
    end

    it "refuses a link that does not decode" do
      get edit_password_path("nao-e-um-token")

      expect(response).to redirect_to(new_password_path)
    end

    it "refuses a link older than fifteen minutes" do
      expired = token

      travel 16.minutes do
        get edit_password_path(expired)

        expect(response).to redirect_to(new_password_path)
      end
    end
  end

  describe "PATCH /passwords/:token" do
    it "changes the password and lets the person sign in with the new one" do
      patch password_path(token), params: { password: new_password, password_confirmation: new_password }

      expect(response).to redirect_to(new_session_path)

      post session_path, params: { email_address: user.email_address, password: new_password }
      expect(response).to redirect_to(root_path)
    end

    it "stops the old password from working" do
      patch password_path(token), params: { password: new_password, password_confirmation: new_password }

      post session_path, params: { email_address: user.email_address, password: old_password }
      expect(Session.count).to be_zero
    end

    it "invalidates the link once the password has changed" do
      used = token
      patch password_path(used), params: { password: new_password, password_confirmation: new_password }

      get edit_password_path(used)
      expect(response).to redirect_to(new_password_path)
    end

    it "refuses a password below the minimum length" do
      patch password_path(token), params: { password: "curta", password_confirmation: "curta" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate(old_password)).to eq(user)
    end

    it "refuses when the confirmation does not match" do
      patch password_path(token), params: { password: new_password, password_confirmation: "outra-coisa" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate(old_password)).to eq(user)
    end

    it "ends every session the account had open" do
      post session_path, params: { email_address: user.email_address, password: old_password }

      expect {
        patch password_path(token), params: { password: new_password, password_confirmation: new_password }
      }.to change(Session, :count).to(0)
    end
  end
end
