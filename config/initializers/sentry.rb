# frozen_string_literal: true

# Constitution principle VI: financial data must never reach Sentry. Request and
# response bodies carry transaction amounts, descriptions and account identifiers,
# so body capture and personally identifying user info stay off.
Sentry.init do |config|
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.dsn = ENV["SENTRY_DSN"]
  config.send_default_pii = false
  config.data_collection.user_info = false
  config.data_collection.url_query_params = false
  config.data_collection.http_bodies = []
  config.traces_sample_rate = 1.0
end
