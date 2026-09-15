class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_registration_path, alert: "Tente novamente em alguns minutos." }

  CONFIRMATION_SENT = "Se este endereço puder criar uma conta, enviamos um link de confirmação para ele.".freeze

  def new
    render Views::Registrations::New.new(user: User.new)
  end

  def create
    user = User.new(registration_params)
    user.validate

    if disclosable_errors(user).any?
      render Views::Registrations::New.new(user:), status: :unprocessable_content
    else
      register(user) if user.errors.empty? && User.signup_allowed?(user.email_address)
      redirect_to new_session_path, notice: CONFIRMATION_SENT
    end
  end

  private
    def registration_params
      params.expect(user: [ :name, :email_address, :password ])
    end

    def register(user)
      user.save!
      UserMailer.confirmation(user).deliver_later
    end

    # An address that is already taken must be indistinguishable from one that is
    # free, so that error alone never reaches the form. Every other problem is
    # the person's own typing and is safe to show.
    def disclosable_errors(user)
      user.errors.reject { |error| error.attribute == :email_address && error.type == :taken }
    end
end
