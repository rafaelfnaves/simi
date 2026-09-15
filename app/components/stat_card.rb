# frozen_string_literal: true

class Components::StatCard < Components::Base
  def initialize(label:, amount:, hint: nil)
    @label = label
    @amount = amount
    @hint = hint
  end

  def view_template
    RubyUI.Card(class: "p-5 flex flex-col gap-1") do
      span(class: "text-sm text-muted-foreground") { @label }
      render Components::Money.new(@amount, class: "text-2xl font-semibold tracking-tight")
      span(class: "text-xs text-muted-foreground") { @hint } if @hint
    end
  end
end
