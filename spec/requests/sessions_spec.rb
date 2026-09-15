require "rails_helper"

RSpec.describe "Sessions" do
  let(:password) { "segredo-muito-bom" }
  let(:user) { create(:user, password: password) }

  describe "GET /session/new" do
    it "is reachable without a session" do
      get new_session_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session" do
    it "signs in a confirmed account" do
      post session_path, params: { email_address: user.email_address, password: password }

      expect(response).to redirect_to(root_path)
      expect(Session.count).to eq(1)
    end

    it "accepts the address however it is typed" do
      post session_path, params: { email_address: user.email_address.upcase, password: password }

      expect(response).to redirect_to(root_path)
    end

    it "refuses a wrong password without revealing whether the address exists" do
      post session_path, params: { email_address: user.email_address, password: "errada" }
      wrong_password = [ response.status, response.location, flash.to_h ]

      post session_path, params: { email_address: "ninguem@exemplo.com", password: "errada" }

      expect([ response.status, response.location, flash.to_h ]).to eq(wrong_password)
      expect(Session.count).to be_zero
    end

    it "refuses an account that has not been confirmed yet" do
      unconfirmed = create(:user, :unconfirmed, password: password)

      post session_path, params: { email_address: unconfirmed.email_address, password: password }

      expect(Session.count).to be_zero
      expect(response).to redirect_to(new_confirmation_path)
    end

    it "returns to the page the visitor originally asked for" do
      get root_path

      post session_path, params: { email_address: user.email_address, password: password }

      expect(response).to redirect_to(root_url)
    end
  end

  describe "DELETE /session" do
    it "ends the session and locks the private pages again" do
      post session_path, params: { email_address: user.email_address, password: password }

      expect { delete session_path }.to change(Session, :count).by(-1)
      expect(response).to have_http_status(:see_other)

      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "a revoked session" do
    it "stops granting access on the next request" do
      post session_path, params: { email_address: user.email_address, password: password }
      Session.destroy_all

      get root_path

      expect(response).to redirect_to(new_session_path)
    end
  end
end
