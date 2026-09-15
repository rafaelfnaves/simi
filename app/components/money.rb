# frozen_string_literal: true

# The one place the product formats money, so every amount reads the same.
class Components::Money < Components::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  # Spelled out here rather than taken from a locale file because the product
  # has no translation layer yet and the currency is not user-selectable.
  BRL = {
    unit: "R$", separator: ",", delimiter: ".", precision: 2,
    format: "%u %n", negative_format: "-%u %n"
  }.freeze

  def initialize(amount, **attrs)
    @amount = amount
    @attrs = attrs
  end

  def view_template
    span(**@attrs) { number_to_currency(@amount, **BRL) }
  end
end
