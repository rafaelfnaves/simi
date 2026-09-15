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
end
