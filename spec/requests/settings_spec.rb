require "rails_helper"

RSpec.describe "Settings" do
  let(:user) { create(:user, name: "Maria Silva") }

  describe "GET /settings/profile" do
    it "requires a session" do
      get settings_profile_path

      expect(response).to redirect_to(new_session_path)
    end

    it "shows the account's own details" do
      sign_in user

      get settings_profile_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Maria Silva", user.email_address)
    end
  end

  describe "PATCH /settings/profile" do
    before { sign_in user }

    it "saves the name and the time zone" do
      patch settings_profile_path, params: { user: { name: "Maria S. Silva", time_zone: "America/New_York" } }

      expect(user.reload.name).to eq("Maria S. Silva")
      expect(user.time_zone).to eq("America/New_York")
    end

    it "shows the new name in the navigation" do
      patch settings_profile_path, params: { user: { name: "Maria S. Silva" } }
      get root_path

      expect(response.body).to include("Maria S. Silva")
    end

    it "refuses a blank name" do
      patch settings_profile_path, params: { user: { name: " " } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.name).to eq("Maria Silva")
    end

    it "ignores an attempt to change the email address" do
      patch settings_profile_path, params: { user: { name: "Maria", email_address: "outra@exemplo.com" } }

      expect(user.reload.email_address).not_to eq("outra@exemplo.com")
    end

    it "edits only the signed in account, never one named in the request" do
      someone_else = create(:user, name: "Outra Pessoa")

      patch settings_profile_path, params: { id: someone_else.id, user: { name: "Invadido" } }

      expect(someone_else.reload.name).to eq("Outra Pessoa")
      expect(user.reload.name).to eq("Invadido")
    end
  end

  describe "PATCH /settings/theme" do
    before { sign_in user }

    it "stores the preference on the account" do
      patch settings_theme_path, params: { theme: "dark" }

      expect(user.reload.theme).to eq("dark")
    end

    it "accepts each of the three themes" do
      User::THEMES.each do |theme|
        patch settings_theme_path, params: { theme: theme }

        expect(user.reload.theme).to eq(theme)
      end
    end

    it "ignores a theme the product does not have" do
      patch settings_theme_path, params: { theme: "sepia" }

      expect(user.reload.theme).to eq("system")
    end

    it "requires a session" do
      delete session_path

      patch settings_theme_path, params: { theme: "dark" }
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "the rendered theme" do
    it "puts the chosen theme on the document for an explicit preference" do
      sign_in create(:user, theme: "dark")

      get root_path

      expect(response.body).to match(/<html[^>]*class="[^"]*dark/)
    end

    it "leaves the document unmarked when the preference is to follow the system" do
      sign_in create(:user, theme: "system")

      get root_path

      expect(response.body).not_to match(/<html[^>]*class="[^"]*(dark|light)/)
    end
  end
end
