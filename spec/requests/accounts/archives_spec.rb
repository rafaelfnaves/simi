require "rails_helper"

RSpec.describe "Account archives" do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /accounts/:account_id/archive" do
    it "takes the account out of the everyday listing without deleting it" do
      account = create(:account, user:, name: "Carteira")

      post account_archive_path(account)

      expect(account.reload).to be_archived
      expect(response).to redirect_to(accounts_path)
    end

    it "answers 404 for an account that is not theirs" do
      other = create(:account)

      post account_archive_path(other)

      expect(response).to have_http_status(:not_found)
      expect(other.reload).to be_active
    end
  end

  describe "DELETE /accounts/:account_id/archive" do
    it "brings the account back with the same balance" do
      account = create(:account, :archived, user:, balance: "1.234,56")

      delete account_archive_path(account)

      expect(account.reload).to be_active
      expect(account.balance).to eq(BigDecimal("1234.56"))
    end

    it "refuses to bring one back when an active account already holds the name" do
      archived = create(:account, :archived, user:, name: "Itaú")
      create(:account, user:, name: "Itaú")

      delete account_archive_path(archived)

      expect(response).to redirect_to(accounts_path)
      expect(flash[:alert]).to eq(I18n.t("accounts.archives.flash.name_taken"))
      expect(archived.reload).to be_archived
    end

    it "refuses with a message when a concurrent request takes the name first" do
      account = create(:account, :archived, user:)
      allow_any_instance_of(Account).to receive(:unarchive!).and_raise(ActiveRecord::RecordNotUnique)

      delete account_archive_path(account)

      expect(response).to redirect_to(accounts_path)
      expect(flash[:alert]).to eq(I18n.t("accounts.archives.flash.name_taken"))
    end
  end
end
