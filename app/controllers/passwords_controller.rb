class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_password_path, alert: t("flash.rate_limited") }

  def new
    render Views::Passwords::New.new
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    PasswordsMailer.reset(user).deliver_later if user

    redirect_to new_session_path, notice: t("passwords.flash.link_sent")
  end

  def edit
    render Views::Passwords::Edit.new(user: @user, token: params[:token])
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: t("passwords.flash.changed")
    else
      render Views::Passwords::Edit.new(user: @user, token: params[:token]),
        status: :unprocessable_content
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: t("passwords.flash.link_invalid")
    end
end
