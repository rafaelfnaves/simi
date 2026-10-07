class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_session_path, alert: t("flash.rate_limited") }

  def new
    render Views::Sessions::New.new
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))

    if user.nil?
      redirect_to new_session_path, alert: t("sessions.flash.rejected")
    elsif !user.confirmed?
      redirect_to new_confirmation_path, alert: t("sessions.flash.confirmation_pending")
    else
      start_new_session_for user
      redirect_to after_authentication_url
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
