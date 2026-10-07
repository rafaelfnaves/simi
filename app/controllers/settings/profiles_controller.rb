class Settings::ProfilesController < ApplicationController
  def show
    render Views::Settings::Profiles::Show.new(user: Current.user)
  end

  def update
    user = Current.user

    if user.update(profile_params)
      redirect_to settings_profile_path, notice: t("settings.profiles.flash.saved")
    else
      render Views::Settings::Profiles::Show.new(user:), status: :unprocessable_content
    end
  end

  private
    # The address is deliberately absent: changing it would need a fresh
    # confirmation round, which is out of scope for this feature.
    def profile_params
      params.expect(user: [ :name, :time_zone, :theme ])
    end
end
