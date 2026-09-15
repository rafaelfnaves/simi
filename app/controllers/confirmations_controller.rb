class ConfirmationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_confirmation_path, alert: "Tente novamente em alguns minutos." }

  LINK_SENT = "Se este endereço tiver um cadastro pendente, enviamos um novo link de confirmação.".freeze
  LINK_INVALID = "Este link de confirmação não vale mais. Podemos enviar outro.".freeze

  def show
    user = User.find_by_token_for(:email_confirmation, params[:token])

    if user.nil?
      redirect_to new_confirmation_path, alert: LINK_INVALID
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

    redirect_to new_session_path, notice: LINK_SENT
  end
end
