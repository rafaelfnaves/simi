require "rails_helper"

RSpec.describe Components::MainNav do
  subject(:fragment) { render_fragment(described_class.new) }

  it "lists every area of the product" do
    expect(fragment.text).to include(
      *I18n.t("components.main_nav").values_at(
        :dashboard, :transactions, :accounts, :cards, :categories, :settings
      )
    )
  end

  it "links the areas that exist" do
    hrefs = fragment.css("a").map { |link| link[:href] }

    expect(hrefs).to include("/", "/accounts", "/categories", "/settings/profile")
  end

  it "marks the areas that are not available yet and does not link them" do
    unavailable = fragment.css("[aria-disabled='true']").map(&:text)

    expect(unavailable.join).to include(
      I18n.t("components.main_nav.transactions"), I18n.t("components.main_nav.cards")
    )
    expect(unavailable.join).not_to include(
      I18n.t("components.main_nav.accounts"), I18n.t("components.main_nav.categories")
    )
    expect(fragment.css("a").map(&:text).join).not_to include(I18n.t("components.main_nav.transactions"))
  end
end
