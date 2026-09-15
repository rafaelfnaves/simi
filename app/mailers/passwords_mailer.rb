class PasswordsMailer < ApplicationMailer
  # @param user [User]
  def reset(user)
    url = edit_password_url(user.password_reset_token)
    expires_in = "#{user.password_reset_token_expires_in.in_minutes.to_i} minutos"

    mail_with(
      to: user.email_address,
      subject: "Redefina sua senha do SIMI",
      html: Views::Mailers::PasswordsMailer::Reset.new(url:, expires_in:),
      text: <<~TEXT
        Você pediu para redefinir sua senha do SIMI.

        Escolha uma nova senha no endereço abaixo:

        #{url}

        O link vale por #{expires_in}. Se não foi você quem pediu, ignore esta mensagem.
      TEXT
    )
  end
end
