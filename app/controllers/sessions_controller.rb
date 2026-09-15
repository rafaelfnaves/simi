class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_session_path, alert: "Tente novamente em alguns minutos." }

  CREDENTIALS_REJECTED = "E-mail ou senha incorretos.".freeze
  CONFIRMATION_PENDING = "Confirme seu cadastro antes de entrar. Podemos enviar um novo link.".freeze

  def new
    render Views::Sessions::New.new
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))

    if user.nil?
      redirect_to new_session_path, alert: CREDENTIALS_REJECTED
    elsif !user.confirmed?
      redirect_to new_confirmation_path, alert: CONFIRMATION_PENDING
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
