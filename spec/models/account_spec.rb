require "rails_helper"

RSpec.describe Account do
  describe "validations" do
    it "requires a name" do
      account = build(:account, name: " ")

      expect(account).not_to be_valid
      expect(account.errors[:name]).to be_present
    end

    it "requires a concrete kind, so the root is never instantiated on its own" do
      expect(described_class.new(user: create(:user), name: "Conta", balance: 0)).not_to be_valid
    end

    it "trims the name and blanks out an empty institution" do
      account = create(:account, name: "  Itaú  ", institution: "   ")

      expect(account.name).to eq("Itaú")
      expect(account.institution).to be_nil
    end
  end

  describe "balance" do
    it "reads money the way people type it in Brazil" do
      expect(create(:account, balance: "1.234,56").balance).to eq(BigDecimal("1234.56"))
    end

    it "accepts a negative balance" do
      expect(create(:account, balance: "-90,00").balance).to eq(BigDecimal("-90"))
    end

    it "accepts zero" do
      expect(create(:account, balance: "0").balance).to eq(0)
    end

    it "refuses a value that does not read as money, instead of silently storing zero" do
      account = build(:account, balance: "mil reais")

      expect(account).not_to be_valid
      expect(account.errors[:balance]).to be_present
    end

    it "refuses a balance the column cannot hold, instead of crashing on save" do
      account = build(:account, balance: "10.000.000.000.000,00")

      expect(account).not_to be_valid
      expect(account.errors.added?(:balance, :too_large)).to be(true)
    end

    it "refuses a negative balance beyond the same limit" do
      expect(build(:account, balance: "-10000000000000")).not_to be_valid
    end

    it "accepts the largest balance the column holds" do
      expect(create(:account, balance: "9.999.999.999.999,99").balance).to eq(BigDecimal("9999999999999.99"))
    end

    it "keeps centavos exact when balances are summed" do
      user = create(:user)
      create(:account, user:, balance: "0,01")
      create(:account, user:, balance: "0,02")

      expect(user.accounts.sum(:balance)).to eq(BigDecimal("0.03"))
    end
  end

  describe "name uniqueness" do
    it "refuses two active accounts with the same name" do
      user = create(:user)
      create(:account, user:, name: "Itaú")

      expect(build(:account, user:, name: "Itaú")).not_to be_valid
    end

    it "ignores case when comparing" do
      user = create(:user)
      create(:account, user:, name: "Itaú")

      expect(build(:account, user:, name: "itaú")).not_to be_valid
    end

    it "allows the name of an archived account to be reused" do
      user = create(:user)
      create(:account, :archived, user:, name: "Itaú")

      expect(build(:account, user:, name: "Itaú")).to be_valid
    end

    it "lets two people use the same name" do
      create(:account, user: create(:user), name: "Itaú")

      expect(build(:account, user: create(:user), name: "Itaú")).to be_valid
    end

    it "holds the invariant in the database, not only in the validation" do
      user = create(:user)
      create(:account, user:, name: "Itaú")
      duplicate = build(:account, user:, name: "Itaú")

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "does not get in the way of editing an archived account" do
      user = create(:user)
      archived = create(:account, :archived, user:, name: "Itaú")
      create(:account, user:, name: "Itaú")

      expect(archived.update(balance: "10,00")).to be(true)
    end
  end

  describe Accounts::Cash do
    it "refuses an institution, because cash has no issuer" do
      expect(build(:cash_account, institution: "Itaú")).not_to be_valid
    end

    it "is valid without one" do
      expect(build(:cash_account)).to be_valid
    end
  end

  describe "kinds" do
    it "maps a form token to the subclass it may create" do
      expect(described_class.class_for("savings")).to eq(Accounts::Savings)
    end

    it "returns nothing for a kind that is not on offer" do
      expect(described_class.class_for("credit_card")).to be_nil
      expect(described_class.class_for("User")).to be_nil
    end

    it "reports its own token" do
      expect(build(:wallet_account).kind).to eq("wallet")
    end
  end

  describe ".deposits" do
    it "finds the accounts that hold money, whatever their leaf class" do
      checking = create(:checking_account)
      savings = create(:savings_account)
      wallet = create(:wallet_account)
      cash = create(:cash_account)

      expect(described_class.deposits).to contain_exactly(checking, savings, wallet, cash)
    end

    # The list is spelled out in Accounts::Deposit::TYPES because an inherited STI
    # condition only knows the leaf classes that happen to be loaded. When feature
    # 003 adds the credit card, this example has to be revisited on purpose: a line
    # of credit must not sum into the consolidated balance.
    it "covers every kind the product offers, and every one of them holds money" do
      expect(Accounts::Deposit::TYPES).to match_array(Account::KINDS.values)
    end
  end

  describe "archiving" do
    it "takes the account out of the active scope and keeps its balance" do
      account = create(:account, balance: "1.234,56")

      account.archive!

      expect(account).to be_archived
      expect(described_class.active).not_to include(account)
      expect(described_class.archived).to include(account)
      expect(account.reload.balance).to eq(BigDecimal("1234.56"))
    end

    it "is idempotent" do
      account = create(:account)
      account.archive!
      archived_at = account.archived_at

      account.archive!

      expect(account.reload.archived_at).to eq(archived_at)
    end

    it "brings the account back with the same balance" do
      account = create(:account, :archived, balance: "1.234,56")

      account.unarchive!

      expect(account).to be_active
      expect(account.balance).to eq(BigDecimal("1234.56"))
    end

    it "refuses to bring back an account whose name is taken by an active one" do
      user = create(:user)
      archived = create(:account, :archived, user:, name: "Itaú")
      create(:account, user:, name: "Itaú")

      expect { archived.unarchive! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "scoping to a user" do
    it "is destroyed with its owner" do
      user = create(:user)
      create(:account, user:)

      expect { user.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
