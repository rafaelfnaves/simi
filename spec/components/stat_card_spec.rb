require "rails_helper"

RSpec.describe Components::StatCard do
  it "renders the label and the amount" do
    fragment = render_fragment(described_class.new(label: "Saldo consolidado", amount: 0))

    expect(fragment.text).to include("Saldo consolidado")
    expect(fragment.text).to include("0,00")
  end

  it "renders a hint when one is given" do
    fragment = render_fragment(
      described_class.new(label: "Receitas do mês", amount: 0, hint: "Nenhuma receita registrada")
    )

    expect(fragment.text).to include("Nenhuma receita registrada")
  end
end
