class UserMailer < ApplicationMailer
  # @param user [User]
  def confirmation(user)
    url = confirmation_url(user.generate_token_for(:email_confirmation))
    expires_in = t("mailers.expires_in.hours", count: User::EMAIL_CONFIRMATION_EXPIRES_IN.in_hours.to_i)

    mail_with(
      to: user.email_address,
      subject: t("mailers.user_mailer.confirmation.subject"),
      html: Views::Mailers::UserMailer::Confirmation.new(user:, url:, expires_in:),
      text: t("mailers.user_mailer.confirmation.text", name: user.name, url:, expires_in:)
    )
  end
end
