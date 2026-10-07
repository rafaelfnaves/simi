# frozen_string_literal: true

class Views::Dashboard::Show < Views::Base
  # @param consolidated_balance [BigDecimal, nil] nil while no account holds money
  def initialize(consolidated_balance: nil)
    @consolidated_balance = consolidated_balance
  end

  def view_template
    render Components::PageHeader.new(title: t(".title"), subtitle: t(".subtitle"))

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
      { label: t(".consolidated"), amount: @consolidated_balance, tone: :signed,
        hint: consolidated_hint },
      { label: t(".income"), amount: 0, hint: t(".income_hint") },
      { label: t(".expenses"), amount: 0, hint: t(".expenses_hint") }
    ]
  end

  def consolidated_hint
    @consolidated_balance.nil? ? t(".consolidated_empty") : t(".consolidated_hint")
  end

  def panels
    %w[ by_category by_project monthly latest ].map do |panel|
      {
        title: t(".#{panel}"),
        empty_title: t(".#{panel}_empty_title"),
        empty_description: t(".#{panel}_empty_description")
      }
    end
  end
end
