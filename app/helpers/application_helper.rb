module ApplicationHelper
  # Empty when the preference is to follow the system — the inline script in the
  # layout settles that case before the first paint.
  #
  # @return [String]
  def theme_class
    theme = Current.user&.theme
    theme.in?(%w[light dark]) ? theme : ""
  end
end
