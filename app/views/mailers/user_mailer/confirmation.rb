# frozen_string_literal: true

class Views::Mailers::UserMailer::Confirmation < Components::Base
  def initialize(user:, url:, expires_in:)
    @user = user
    @url = url
    @expires_in = expires_in
  end

  def view_template
    p { t(".greeting", name: @user.name) }
    p { t(".body") }
    p { a(href: @url) { t(".action") } }
    p { t(".expiry", expires_in: @expires_in) }
  end
end
