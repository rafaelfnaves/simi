require "rails_helper"

RSpec.describe Components::StatCard do
  it "renders the label and the amount" do
    fragment = render_fragment(described_class.new(label: "Saldo consolidado", amount: 0))

    expect(fragment.text).to include("Saldo consolidado")
    expect(fragment.text).to include("0,00")
  end

  it "holds the empty state instead of a zero that would look like a real balance" do
    fragment = render_fragment(
      described_class.new(label: "Saldo consolidado", amount: nil, hint: "Cadastre suas contas")
    )

    expect(fragment.text).to include("Saldo consolidado", "Cadastre suas contas")
    expect(fragment.text).not_to include("R$")
  end

  it "marks a negative amount when asked to" do
    fragment = render_fragment(
      described_class.new(label: "Saldo consolidado", amount: -90, tone: :signed)
    )

    expect(fragment.to_html).to include("text-destructive")
  end

  it "renders a hint when one is given" do
    fragment = render_fragment(
      described_class.new(label: "Receitas do mês", amount: 0, hint: "Nenhuma receita registrada")
    )

    expect(fragment.text).to include("Nenhuma receita registrada")
  end
end
