# frozen_string_literal: true

module SignupAllowlist
  def allow_signups_from(*email_addresses)
    ENV["SIMI_ALLOWED_SIGNUP_EMAILS"] = email_addresses.join(",")
  end
end

RSpec.configure do |config|
  config.include SignupAllowlist

  config.around do |example|
    original = ENV["SIMI_ALLOWED_SIGNUP_EMAILS"]
    ENV["SIMI_ALLOWED_SIGNUP_EMAILS"] = ""
    example.run
    ENV["SIMI_ALLOWED_SIGNUP_EMAILS"] = original
  end
end
