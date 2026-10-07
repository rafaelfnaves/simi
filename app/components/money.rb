# frozen_string_literal: true

# The one place the product formats money, so every amount reads the same.
class Components::Money < Components::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  # @param tone [Symbol, nil] `:signed` marks a negative amount as money the person
  #   owes rather than holds; the default leaves the colour to whatever contains it
  def initialize(amount, tone: nil, **attrs)
    @amount = amount
    @tone = tone
    @attrs = attrs
  end

  def view_template
    span(**attributes) { number_to_currency(@amount) }
  end

  private

  def attributes
    @attrs.merge(class: [ @attrs[:class], tone_class ].compact.presence)
  end

  def tone_class
    "text-destructive" if @tone == :signed && @amount.to_d.negative?
  end
end
