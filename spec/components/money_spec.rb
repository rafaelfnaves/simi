require "rails_helper"

RSpec.describe Components::Money do
  def rendered(amount) = render_component(described_class.new(amount)).strip

  it "formats in Brazilian reais" do
    expect(rendered(1234.56)).to include("R$")
    expect(rendered(1234.56)).to include("1.234,56")
  end

  it "shows zero rather than hiding it" do
    expect(rendered(0)).to include("0,00")
  end

  it "keeps the sign on a negative amount" do
    expect(rendered(-90.5)).to include("-")
    expect(rendered(-90.5)).to include("90,50")
  end

  it "always shows two decimal places" do
    expect(rendered(7)).to include("7,00")
  end

  it "accepts a decimal without losing precision" do
    expect(rendered(BigDecimal("1234567.89"))).to include("1.234.567,89")
  end

  describe "tone: :signed" do
    def signed(amount) = render_fragment(described_class.new(amount, tone: :signed)).at_css("span")

    it "marks a negative amount as money the person owes" do
      expect(signed(-90.5)["class"]).to include("text-destructive")
    end

    it "leaves a positive amount to the colour of whatever contains it" do
      expect(signed(90.5)["class"]).to be_nil
    end

    it "treats zero as not negative" do
      expect(signed(0)["class"]).to be_nil
    end

    it "keeps the classes it was given" do
      fragment = render_fragment(described_class.new(-1, tone: :signed, class: "text-2xl"))

      expect(fragment.at_css("span")["class"]).to include("text-2xl", "text-destructive")
    end
  end
end
