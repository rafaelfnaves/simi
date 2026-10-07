class ApplicationController < ActionController::Base
  include Authentication

  # Declared after Authentication so that Current.user is already resolved when it
  # runs. Nobody can pick another locale yet, but the preference lives on the
  # account rather than on the browser, like the theme does.
  around_action :switch_locale
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private
    def switch_locale(&)
      I18n.with_locale(Current.user&.locale, &)
    end
end
