# frozen_string_literal: true

class Views::Mailers::PasswordsMailer::Reset < Components::Base
  def initialize(url:, expires_in:)
    @url = url
    @expires_in = expires_in
  end

  def view_template
    p { "Você pediu para redefinir sua senha do SIMI." }
    p { a(href: @url) { "Escolher uma nova senha" } }
    p { "O link vale por #{@expires_in}. Se não foi você quem pediu, ignore esta mensagem." }
  end
end
