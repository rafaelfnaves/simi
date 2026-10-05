# frozen_string_literal: true

# Reads money the way people type it in Brazil.
#
# This is a type and not a `normalizes` block because normalization runs *after*
# Active Record casts the value: by then `"1.234,56"` has already been read as
# `1.234`. The statement import of roadmap phase 3 reuses the same conversion.
class MoneyType < ActiveRecord::Type::Decimal
  # Every spelling the product accepts: either the Brazilian form, where dots
  # group thousands and a comma opens the cents, or a plain number.
  ACCEPTED = /\A[+-]?\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?\z|\A[+-]?\d+(?:[.,]\d{1,2})?\z/

  THOUSANDS_ONLY = /\A[+-]?\d{1,3}(?:\.\d{3})+\z/
  private_constant :THOUSANDS_ONLY

  class << self
    # Whether a value typed by a person reads as money. A model validates against
    # this instead of `numericality`, which would reject `"1.234,56"` outright
    # because it inspects the value before this type has touched it.
    #
    # @param value [Object]
    # @return [Boolean]
    def accepts?(value)
      value.is_a?(::String) && ACCEPTED.match?(bare(value))
    end

    # @param string [String]
    # @return [String] the number without currency symbol or whitespace
    def bare(string)
      string.strip.delete(" ").sub(/\AR\$\s*/, "").gsub(/\s/, "")
    end
  end

  # @param value [Object] what was assigned to the attribute
  # @return [BigDecimal, nil] `"1.234,56"` and `"1234.56"` both become `1234.56`
  def cast(value)
    value.is_a?(::String) ? super(normalize(value)) : super
  end

  private
    # Without this, assigning the same Brazilian-formatted string twice marks the
    # record dirty, because the numeric helper sees a non-numeric string.
    def non_numeric_string?(value)
      super(value.is_a?(::String) ? normalize(value) : value)
    end

    def normalize(string)
      bare = self.class.bare(string)

      return bare.delete(".").tr(",", ".") if bare.include?(",")
      return bare.delete(".") if bare.match?(THOUSANDS_ONLY)

      bare
    end
end
