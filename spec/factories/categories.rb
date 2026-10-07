FactoryBot.define do
  factory :category do
    user
    sequence(:name) { |n| "Categoria #{n}" }
    nature { "expense" }
    color { Category::COLORS.keys.sample }
    icon { Category::ICONS.sample }

    trait :income do
      nature { "income" }
    end

    trait :archived do
      archived_at { 1.day.ago }
    end

    # The parent carries the user, because a subcategory of someone else's category
    # is not a thing the product allows.
    trait :subcategory do
      parent { association :category, user: }
    end
  end
end
