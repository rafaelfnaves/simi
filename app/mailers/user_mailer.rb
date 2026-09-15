class UserMailer < ApplicationMailer
  # @param user [User]
  def confirmation(user)
    url = confirmation_url(user.generate_token_for(:email_confirmation))
    expires_in = "#{User::EMAIL_CONFIRMATION_EXPIRES_IN.in_hours.to_i} horas"

    mail_with(
      to: user.email_address,
      subject: "Confirme seu cadastro no SIMI",
      html: Views::Mailers::UserMailer::Confirmation.new(user:, url:, expires_in:),
      text: <<~TEXT
        Olá, #{user.name}.

        Confirme seu cadastro no SIMI abrindo o endereço abaixo:

        #{url}

        O link vale por #{expires_in}. Se não foi você quem se cadastrou, ignore esta mensagem.
      TEXT
    )
  end
end
