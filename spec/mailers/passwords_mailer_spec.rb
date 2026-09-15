require "rails_helper"

RSpec.describe PasswordsMailer do
  describe "#reset" do
    let(:user) { create(:user, password: "segredo-muito-bom") }
    let(:mail) { described_class.reset(user) }

    it "goes to the account's address" do
      expect(mail.to).to eq([ user.email_address ])
    end

    it "announces itself" do
      expect(mail.subject).to eq("Redefina sua senha do SIMI")
    end

    it "is multipart, with an HTML and a plain text alternative" do
      expect(mail).to be_multipart
      expect(mail.html_part.body.to_s).to be_present
      expect(mail.text_part.body.to_s).to be_present
    end

    it "carries a link that actually resolves to this account" do
      token = mail.html_part.body.to_s[%r{/passwords/([^"/?]+)/edit}, 1]

      expect(User.find_by_password_reset_token(token)).to eq(user)
    end

    it "never carries the password" do
      expect(mail.body.to_s).not_to include("segredo-muito-bom")
    end
  end
end
