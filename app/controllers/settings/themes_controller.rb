class Settings::ThemesController < ApplicationController
  def update
    theme = params[:theme]
    Current.user.update(theme:) if theme.in?(User::THEMES)

    redirect_back fallback_location: root_path
  end
end
