# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.dsn = ENV["SENTRY_DSN"]
  config.data_collection.user_info = true
  config.data_collection.url_query_params = true
  config.data_collection.http_bodies = [ :incoming_request, :outgoing_request ]
  config.traces_sample_rate = 1.0
end
