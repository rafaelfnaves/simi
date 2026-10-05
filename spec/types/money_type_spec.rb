# frozen_string_literal: true

require "rails_helper"

RSpec.describe MoneyType do
  subject(:type) { described_class.new(precision: 15, scale: 2) }

  describe "#cast" do
    it "reads the Brazilian form, with and without a thousands separator" do
      expect(type.cast("1.234,56")).to eq(BigDecimal("1234.56"))
      expect(type.cast("1234,56")).to eq(BigDecimal("1234.56"))
      expect(type.cast("1.234.567,89")).to eq(BigDecimal("1234567.89"))
    end

    it "reads a plain number unchanged" do
      expect(type.cast("1234.56")).to eq(BigDecimal("1234.56"))
      expect(type.cast("0")).to eq(BigDecimal("0"))
      expect(type.cast(1234.56)).to eq(BigDecimal("1234.56"))
    end

    it "treats dots alone as a thousands separator" do
      expect(type.cast("1.234")).to eq(BigDecimal("1234"))
      expect(type.cast("1.234.567")).to eq(BigDecimal("1234567"))
    end

    it "keeps the sign of a negative balance" do
      expect(type.cast("-90,00")).to eq(BigDecimal("-90"))
      expect(type.cast("-1.234,56")).to eq(BigDecimal("-1234.56"))
    end

    it "tolerates currency symbols and stray spaces around the value" do
      expect(type.cast(" R$ 1.234,56 ")).to eq(BigDecimal("1234.56"))
    end

    it "rounds to two decimals" do
      expect(type.cast("1,239")).to eq(BigDecimal("1.24"))
    end

    it "casts a blank string to nil" do
      expect(type.cast("")).to be_nil
      expect(type.cast("   ")).to be_nil
    end

    it "passes nil through" do
      expect(type.cast(nil)).to be_nil
    end
  end

  describe ".accepts?" do
    it "accepts every spelling the product takes from a form" do
      expect([ "1.234,56", "1234,56", "1234.56", "1.234", "0", "-90,00", "R$ 1.234,56" ])
        .to all(satisfy { |value| described_class.accepts?(value) })
    end

    it "rejects what is not money" do
      expect([ "abc", "12abc", "1,234,56", "1.2.3", "", nil, 10 ])
        .to all(satisfy { |value| !described_class.accepts?(value) })
    end
  end

  describe "ACCEPTED" do
    it "matches every spelling the product accepts" do
      expect([ "1.234,56", "1234,56", "1234.56", "1.234", "0", "-90,00", "+1,5" ])
        .to all(match(described_class::ACCEPTED))
    end

    it "rejects what is not a number" do
      expect([ "abc", "12abc", "1,234,56", "1.2.3", "", "R$ 10" ])
        .to all(satisfy { |value| !described_class::ACCEPTED.match?(value) })
    end
  end
end
