class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_password_path, alert: "Tente novamente em alguns minutos." }

  LINK_SENT = "Se existir uma conta com esse e-mail, enviamos um link para redefinir a senha.".freeze
  LINK_INVALID = "Este link de redefinição não vale mais. Peça um novo.".freeze
  PASSWORD_CHANGED = "Senha alterada. Entre com a nova senha.".freeze

  def new
    render Views::Passwords::New.new
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    PasswordsMailer.reset(user).deliver_later if user

    redirect_to new_session_path, notice: LINK_SENT
  end

  def edit
    render Views::Passwords::Edit.new(user: @user, token: params[:token])
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: PASSWORD_CHANGED
    else
      render Views::Passwords::Edit.new(user: @user, token: params[:token]),
        status: :unprocessable_content
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: LINK_INVALID
    end
end
