# frozen_string_literal: true

require "rails_helper"

# Constitution principle VI: financial data must never reach logs or Sentry.
RSpec.describe "Data privacy configuration" do
  describe "log parameter filtering" do
    # Rails compiles config.filter_parameters into a single Regexp the first time
    # a request is filtered, so these assert on behaviour rather than on the
    # shape of the list.
    subject(:filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }

    it "redacts credentials" do
      filtered = filter.filter(
        "password" => "segredo", "email_address" => "maria@exemplo.com",
        "token" => "abc", "secret" => "x", "password_salt" => "y"
      )

      expect(filtered.values).to all(eq("[FILTERED]"))
    end

    it "redacts financial values" do
      filtered = filter.filter(
        "amount" => "1234.56", "balance" => "-90.00", "description" => "Restaurante",
        "notes" => "almoço", "account_number" => "12345-6", "card_last_four" => "4321",
        "statement" => "extrato.pdf"
      )

      expect(filtered.values).to all(eq("[FILTERED]"))
    end

    it "redacts a whole account form, name and institution included" do
      filtered = filter.filter("account" => { "name" => "Itaú", "institution" => "Itaú Unibanco", "balance" => "1.234,56" })

      expect(filtered["account"]).to eq("[FILTERED]")
    end

    it "redacts a category form, whose names describe how the person spends" do
      filtered = filter.filter("category" => { "name" => "Terapia", "nature" => "expense" })

      expect(filtered["category"]).to eq("[FILTERED]")
    end

    it "leaves harmless parameters alone" do
      expect(filter.filter("page" => "2", "theme" => "dark")).to eq("page" => "2", "theme" => "dark")
    end
  end

  describe "Sentry" do
    let(:config) { Sentry.configuration }

    it "does not send request or response bodies" do
      expect(config.data_collection.http_bodies).to be_empty
    end

    it "does not send personally identifying user info" do
      expect(config.data_collection.user_info).to be(false)
      expect(config.send_default_pii).to be(false)
    end

    it "does not send query strings" do
      expect(config.data_collection.url_query_params.mode).to be(:off)
    end
  end
end
