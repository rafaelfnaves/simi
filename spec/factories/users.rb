FactoryBot.define do
  factory :user do
    name { FFaker::NameBR.name }
    email_address { FFaker::Internet.safe_email }
    password { FFaker::Internet.password(12) }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
