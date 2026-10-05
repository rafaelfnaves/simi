require "rails_helper"

RSpec.describe Components::CategoryBadge do
  let(:category) { build(:category, name: "Alimentação", color: "amber", icon: "food") }

  subject(:fragment) { render_fragment(described_class.new(category)) }

  it "names the category" do
    expect(fragment.text).to include("Alimentação")
  end

  it "wears the literal classes of its colour" do
    expect(fragment.at_css("span")["class"]).to include(Category::COLORS.fetch("amber"))
  end

  it "draws its icon" do
    expect(fragment.at_css("svg")).to be_present
  end
end
