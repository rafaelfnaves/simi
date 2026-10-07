class PasswordsMailer < ApplicationMailer
  # @param user [User]
  def reset(user)
    url = edit_password_url(user.password_reset_token)
    expires_in = t("mailers.expires_in.minutes", count: user.password_reset_token_expires_in.in_minutes.to_i)

    mail_with(
      to: user.email_address,
      subject: t("mailers.passwords_mailer.reset.subject"),
      html: Views::Mailers::PasswordsMailer::Reset.new(url:, expires_in:),
      text: t("mailers.passwords_mailer.reset.text", url:, expires_in:)
    )
  end
end
