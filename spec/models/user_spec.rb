require "rails_helper"

RSpec.describe User do
  describe "email address" do
    it "strips and downcases on write" do
      user = create(:user, email_address: "  Maria@Exemplo.COM ")

      expect(user.email_address).to eq("maria@exemplo.com")
    end

    it "finds a record regardless of how the address is typed" do
      user = create(:user, email_address: "maria@exemplo.com")

      expect(User.find_by(email_address: " Maria@Exemplo.com ")).to eq(user)
    end

    it "rejects a duplicate that differs only by case" do
      create(:user, email_address: "maria@exemplo.com")
      duplicate = build(:user, email_address: "MARIA@exemplo.com")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email_address]).to be_present
    end
  end

  describe "name" do
    it "strips surrounding whitespace" do
      expect(create(:user, name: "  Maria Silva  ").name).to eq("Maria Silva")
    end

    it "is required" do
      expect(build(:user, name: " ")).not_to be_valid
    end
  end

  describe "password" do
    it "rejects anything shorter than the minimum" do
      user = build(:user, password: "a" * (User::MINIMUM_PASSWORD_LENGTH - 1))

      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "accepts the minimum length" do
      expect(build(:user, password: "a" * User::MINIMUM_PASSWORD_LENGTH)).to be_valid
    end

    it "is stored only as a digest" do
      user = create(:user, password: "segredo-muito-bom")

      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to include("segredo-muito-bom")
      expect(user.authenticate("segredo-muito-bom")).to eq(user)
    end
  end

  describe "theme" do
    it "defaults to following the system" do
      expect(create(:user).theme).to eq("system")
    end

    it "accepts only the three known values" do
      expect(User::THEMES).to contain_exactly("system", "light", "dark")
      User::THEMES.each { |theme| expect(build(:user, theme:)).to be_valid }
      expect(build(:user, theme: "sepia")).not_to be_valid
    end
  end

  describe "time zone" do
    it "defaults to São Paulo" do
      expect(create(:user).time_zone).to eq("America/Sao_Paulo")
    end

    it "rejects a zone Rails does not know" do
      expect(build(:user, time_zone: "Mars/Olympus")).not_to be_valid
    end
  end

  describe "confirmation" do
    it "starts unconfirmed when built without a timestamp" do
      expect(build(:user, :unconfirmed)).not_to be_confirmed
    end

    it "round-trips a confirmation token" do
      user = create(:user, :unconfirmed)

      expect(User.find_by_token_for(:email_confirmation, user.generate_token_for(:email_confirmation)))
        .to eq(user)
    end

    it "refuses a token older than 24 hours" do
      user = create(:user, :unconfirmed)
      token = user.generate_token_for(:email_confirmation)

      travel 25.hours do
        expect(User.find_by_token_for(:email_confirmation, token)).to be_nil
      end
    end

    it "invalidates the token when the address changes" do
      user = create(:user, :unconfirmed)
      token = user.generate_token_for(:email_confirmation)
      user.update!(email_address: "outro@exemplo.com")

      expect(User.find_by_token_for(:email_confirmation, token)).to be_nil
    end

    it "records the moment of confirmation, and only once" do
      user = create(:user, :unconfirmed)
      user.confirm!
      first = user.confirmed_at

      travel 1.hour do
        user.confirm!
        expect(user.reload.confirmed_at).to eq(first)
      end
    end
  end

  describe ".signup_allowed?" do
    around do |example|
      original = ENV["SIMI_ALLOWED_SIGNUP_EMAILS"]
      example.run
      ENV["SIMI_ALLOWED_SIGNUP_EMAILS"] = original
    end

    it "accepts an address on the list, however it is typed" do
      ENV["SIMI_ALLOWED_SIGNUP_EMAILS"] = "maria@exemplo.com, joao@exemplo.com"

      expect(User).to be_signup_allowed(" MARIA@Exemplo.com ")
      expect(User).to be_signup_allowed("joao@exemplo.com")
    end

    it "refuses an address that is not on the list" do
      ENV["SIMI_ALLOWED_SIGNUP_EMAILS"] = "maria@exemplo.com"

      expect(User).not_to be_signup_allowed("intruso@exemplo.com")
    end

    it "refuses everyone when the list is empty" do
      ENV["SIMI_ALLOWED_SIGNUP_EMAILS"] = "   "

      expect(User.allowed_signup_email_addresses).to be_empty
      expect(User).not_to be_signup_allowed("maria@exemplo.com")
    end

    it "refuses everyone when the variable is absent" do
      ENV.delete("SIMI_ALLOWED_SIGNUP_EMAILS")

      expect(User).not_to be_signup_allowed("maria@exemplo.com")
    end

    it "refuses a blank address" do
      ENV["SIMI_ALLOWED_SIGNUP_EMAILS"] = "maria@exemplo.com"

      expect(User).not_to be_signup_allowed(nil)
      expect(User).not_to be_signup_allowed("  ")
    end
  end

  describe "sessions" do
    it "destroys them along with the user" do
      user = create(:user)
      user.sessions.create!(ip_address: "203.0.113.10", user_agent: "rspec")

      expect { user.destroy }.to change(Session, :count).by(-1)
    end
  end
end
