# frozen_string_literal: true

# The trigger in the topbar. The account is the source of truth for the theme
# (FR-029), so the click goes to the server; the Stimulus controller only flips
# the class on `<html>` so the change is felt before the response lands.
class Components::ThemeSwitcher < Components::Base
  include Phlex::Rails::Helpers::FormAuthenticityToken


  def initialize(theme:)
    @theme = theme
  end

  def view_template
    form(**form_attrs) do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
      input(type: "hidden", name: "_method", value: "patch")
      input(type: "hidden", name: "theme", value: next_theme, data: { theme_target: "field" })

      RubyUI.Toggle(pressed: dark?, aria: { label: t(".label") }) do
        moon_icon
        sun_icon
      end
    end
  end

  private

  def form_attrs
    {
      action: settings_theme_path,
      method: "post",
      class: "contents",
      data: { controller: "theme", action: "click->theme#apply", theme_preference_value: @theme }
    }
  end

  def dark? = @theme == "dark"

  # An account that follows the system is offered the dark theme; only the
  # browser knows which one is actually painted, and the Stimulus controller
  # corrects the value as soon as it connects.
  def next_theme = dark? ? "light" : "dark"

  # Which icon shows is decided by the `dark` class on `<html>`, so it stays
  # right for an account that follows the system without asking the server.
  def moon_icon
    svg(**icon_attrs("size-4 dark:hidden")) do |s|
      s.path(d: "M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z")
    end
  end

  def sun_icon
    svg(**icon_attrs("size-4 hidden dark:block")) do |s|
      s.circle(cx: "12", cy: "12", r: "4")
      s.path(d: "M12 2v2m0 16v2M4.93 4.93l1.41 1.41m11.32 11.32 1.41 1.41M2 12h2m16 0h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41")
    end
  end

  def icon_attrs(classes)
    {
      class: classes,
      xmlns: "http://www.w3.org/2000/svg",
      viewbox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      stroke_width: "2",
      stroke_linecap: "round",
      stroke_linejoin: "round",
      aria_hidden: "true"
    }
  end
end
