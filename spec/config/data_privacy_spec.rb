# frozen_string_literal: true

require "rails_helper"

# Constitution principle VI: financial data must never reach logs or Sentry.
RSpec.describe "Data privacy configuration" do
  describe "log parameter filtering" do
    let(:filters) { Rails.application.config.filter_parameters }

    it "filters credentials" do
      expect(filters).to include(:passw, :email, :secret, :token, :crypt, :salt)
    end

    it "filters financial parameters" do
      expect(filters).to include(:amount, :balance, :description, :account, :card, :statement)
    end

    it "redacts filtered values" do
      filtered = ActiveSupport::ParameterFilter.new(filters)
        .filter("amount" => "1234.56", "description" => "Restaurante")

      expect(filtered.values).to all(eq("[FILTERED]"))
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
