# frozen_string_literal: true

class Components::StatCard < Components::Base
  # @param amount [Numeric, nil] nil holds the empty state: a zero here would read
  #   as a real balance
  # @param tone [Symbol, nil] passed through to Components::Money
  def initialize(label:, amount:, hint: nil, tone: nil)
    @label = label
    @amount = amount
    @hint = hint
    @tone = tone
  end

  def view_template
    RubyUI.Card(class: "p-5 flex flex-col gap-1") do
      span(class: "text-sm text-muted-foreground") { @label }

      if @amount.nil?
        span(class: "text-sm text-muted-foreground") { @hint } if @hint
      else
        render Components::Money.new(
          @amount, tone: @tone, class: "text-2xl font-semibold tracking-tight"
        )
        span(class: "text-xs text-muted-foreground") { @hint } if @hint
      end
    end
  end
end
