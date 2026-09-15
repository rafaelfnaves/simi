require "rails_helper"

RSpec.describe UserMailer do
  describe "#confirmation" do
    let(:user) { create(:user, :unconfirmed, name: "Maria Silva", password: "segredo-muito-bom") }
    let(:mail) { described_class.confirmation(user) }

    it "goes to the address being confirmed" do
      expect(mail.to).to eq([ user.email_address ])
    end

    it "announces itself" do
      expect(mail.subject).to eq("Confirme seu cadastro no SIMI")
    end

    it "is multipart, with an HTML and a plain text alternative" do
      expect(mail).to be_multipart
      expect(mail.html_part.body.to_s).to be_present
      expect(mail.text_part.body.to_s).to be_present
    end

    it "carries a confirmation link in both parts" do
      [ mail.html_part, mail.text_part ].each do |part|
        expect(part.body.to_s).to include("/confirmations/")
      end
    end

    it "carries a link that actually resolves to this account" do
      token = mail.html_part.body.to_s[%r{/confirmations/([^"?]+)}, 1]

      expect(User.find_by_token_for(:email_confirmation, token)).to eq(user)
    end

    it "greets the person by name" do
      expect(mail.html_part.body.to_s).to include("Maria Silva")
    end

    it "never carries the password" do
      expect(mail.body.to_s).not_to include("segredo-muito-bom")
    end
  end
end
