# frozen_string_literal: true

class Views::Dashboard::Show < Views::Base
  # @param consolidated_balance [BigDecimal, nil] nil while no account holds money
  def initialize(consolidated_balance: nil)
    @consolidated_balance = consolidated_balance
  end

  def view_template
    render Components::PageHeader.new(
      title: "Dashboard",
      subtitle: "Sua vida financeira em um só lugar."
    )

    div(class: "grid gap-4 sm:grid-cols-2 lg:grid-cols-3") do
      metrics.each { |metric| render Components::StatCard.new(**metric) }
    end

    div(class: "grid gap-4 lg:grid-cols-2") do
      panels.each { |panel| render Components::DashboardPanel.new(**panel) }
    end
  end

  private

  def metrics
    [
      { label: "Saldo consolidado", amount: @consolidated_balance, tone: :signed,
        hint: consolidated_hint },
      { label: "Receitas do mês", amount: 0, hint: "Nenhuma receita registrada neste mês." },
      { label: "Despesas do mês", amount: 0, hint: "Nenhuma despesa registrada neste mês." }
    ]
  end

  def consolidated_hint
    if @consolidated_balance.nil?
      "Cadastre suas contas para ver o saldo."
    else
      "Soma das contas ativas."
    end
  end

  def panels
    [
      {
        title: "Gastos por categoria",
        empty_title: "Nada para mostrar ainda",
        empty_description: "Quando houver despesas categorizadas, elas aparecem aqui divididas por categoria."
      },
      {
        title: "Despesas por projeto",
        empty_title: "Nenhum projeto em andamento",
        empty_description: "Agrupe gastos de uma viagem ou reforma em um projeto para acompanhar o total."
      },
      {
        title: "Evolução mensal",
        empty_title: "Ainda sem histórico",
        empty_description: "Depois de alguns meses de lançamentos, a evolução das suas receitas e despesas aparece aqui."
      },
      {
        title: "Últimas movimentações",
        empty_title: "Nenhuma movimentação",
        empty_description: "Importe um extrato ou registre um lançamento para começar."
      }
    ]
  end
end
