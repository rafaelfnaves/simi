class ConfirmationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_confirmation_path, alert: t("flash.rate_limited") }

  def show
    user = User.find_by_token_for(:email_confirmation, params[:token])

    if user.nil?
      redirect_to new_confirmation_path, alert: t("confirmations.flash.link_invalid")
    else
      user.confirm!
      start_new_session_for user
      redirect_to after_authentication_url
    end
  end

  def new
    render Views::Confirmations::New.new
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    UserMailer.confirmation(user).deliver_later if user && !user.confirmed?

    redirect_to new_session_path, notice: t("confirmations.flash.link_sent")
  end
end
