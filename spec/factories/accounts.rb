FactoryBot.define do
  factory :account, class: "Accounts::Checking" do
    user
    sequence(:name) { |n| "#{FFaker::Company.name} #{n}" }
    institution { FFaker::Company.name }
    balance { 1234.56 }

    trait :archived do
      archived_at { 1.day.ago }
    end

    trait :negative do
      balance { -90.0 }
    end

    factory :checking_account, class: "Accounts::Checking"
    factory :savings_account, class: "Accounts::Savings"
    factory :wallet_account, class: "Accounts::Wallet"

    factory :cash_account, class: "Accounts::Cash" do
      institution { nil }
    end
  end
end
