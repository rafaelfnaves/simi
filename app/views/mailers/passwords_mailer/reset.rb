# frozen_string_literal: true

class Views::Mailers::PasswordsMailer::Reset < Components::Base
  def initialize(url:, expires_in:)
    @url = url
    @expires_in = expires_in
  end

  def view_template
    p { t(".body") }
    p { a(href: @url) { t(".action") } }
    p { t(".expiry", expires_in: @expires_in) }
  end
end
