require "rails_helper"

RSpec.describe "Accounts" do
  let(:user) { create(:user) }

  describe "GET /accounts" do
    it "requires a session" do
      get accounts_path

      expect(response).to redirect_to(new_session_path)
    end

    it "explains what an account is on the first visit" do
      sign_in user

      get accounts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("views.accounts.index.empty_title"))
    end

    it "lists the accounts with their balances" do
      create(:account, user:, name: "Itaú", balance: "1.234,56")
      sign_in user

      get accounts_path

      expect(response.body).to include("Itaú", "1.234,56")
    end

    it "marks the archived ones apart" do
      create(:account, :archived, user:, name: "Carteira antiga")
      sign_in user

      get accounts_path

      expect(response.body).to include("Carteira antiga", I18n.t("views.accounts.index.archived"))
    end

    it "never shows someone else's accounts" do
      create(:account, name: "Conta alheia")
      sign_in user

      get accounts_path

      expect(response.body).not_to include("Conta alheia")
    end
  end

  describe "POST /accounts" do
    before { sign_in user }

    it "creates the account, reading the balance as people type it in Brazil" do
      post accounts_path, params: { account: { kind: "checking", name: "Itaú", institution: "Itaú", balance: "1.234,56" } }

      account = user.accounts.sole
      expect(account).to be_a(Accounts::Checking)
      expect(account.balance).to eq(BigDecimal("1234.56"))
      expect(response).to redirect_to(accounts_path)
    end

    it "accepts a negative balance" do
      post accounts_path, params: { account: { kind: "wallet", name: "Carteira", balance: "-90,00" } }

      expect(user.accounts.sole.balance).to eq(BigDecimal("-90"))
    end

    it "refuses an account without a name" do
      post accounts_path, params: { account: { kind: "checking", name: "", balance: "0" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.accounts).to be_empty
    end

    it "refuses a kind the product does not offer" do
      post accounts_path, params: { account: { kind: "crypto", name: "Binance", balance: "0" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.accounts).to be_empty
    end

    it "refuses a balance that does not read as money" do
      post accounts_path, params: { account: { kind: "checking", name: "Itaú", balance: "mil reais" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.accounts).to be_empty
    end

    it "refuses a name already taken by an active account" do
      create(:account, user:, name: "Itaú")

      post accounts_path, params: { account: { kind: "savings", name: "Itaú", balance: "0" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.accounts.count).to eq(1)
    end

    it "refuses cash with an institution, because cash has no issuer" do
      post accounts_path, params: { account: { kind: "cash", name: "Dinheiro", institution: "Itaú", balance: "50" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.accounts).to be_empty
    end

    it "ignores a type smuggled in through the form" do
      post accounts_path, params: {
        account: { kind: "checking", type: "Accounts::CreditCard", name: "Itaú", balance: "0" }
      }

      expect(user.accounts.sole).to be_an_instance_of(Accounts::Checking)
    end
  end

  describe "GET /accounts/:id/edit" do
    it "opens the person's own account" do
      account = create(:account, user:, name: "Itaú")
      sign_in user

      get edit_account_path(account)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Itaú")
    end

    # The body is not asserted on: in test the debug page quotes the source of this
    # very file, so it would echo the name no matter what the product leaked.
    it "answers 404 for an account that is not theirs" do
      account = create(:account, name: "Conta alheia")
      sign_in user

      get edit_account_path(account)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /accounts/:id" do
    before { sign_in user }

    it "saves the new name and institution" do
      account = create(:account, user:, name: "Itaú")

      patch account_path(account), params: { account: { name: "Itaú — conta salário", institution: "Itaú Unibanco" } }

      expect(account.reload.name).to eq("Itaú — conta salário")
      expect(account.institution).to eq("Itaú Unibanco")
    end

    it "refuses a blank name" do
      account = create(:account, user:, name: "Itaú")

      patch account_path(account), params: { account: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(account.reload.name).to eq("Itaú")
    end

    it "does not let the kind change in an edit" do
      account = create(:account, user:)

      patch account_path(account), params: { account: { kind: "savings" } }

      expect(account.reload).to be_an_instance_of(Accounts::Checking)
    end

    it "answers 404 for an account that is not theirs" do
      patch account_path(create(:account)), params: { account: { name: "Invadida" } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /accounts/:id" do
    before { sign_in user }

    it "deletes an account that has nothing attached to it" do
      account = create(:account, user:)

      expect { delete account_path(account) }.to change { user.accounts.count }.by(-1)
      expect(response).to redirect_to(accounts_path)
    end

    it "answers 404 for an account that is not theirs" do
      other = create(:account)

      delete account_path(other)

      expect(response).to have_http_status(:not_found)
      expect(other.reload).to be_persisted
    end
  end
end
