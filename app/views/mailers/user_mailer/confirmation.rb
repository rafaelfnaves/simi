# frozen_string_literal: true

class Views::Mailers::UserMailer::Confirmation < Components::Base
  def initialize(user:, url:, expires_in:)
    @user = user
    @url = url
    @expires_in = expires_in
  end

  def view_template
    p { "Olá, #{@user.name}." }
    p { "Confirme seu cadastro no SIMI para começar a usar sua conta." }
    p { a(href: @url) { "Confirmar meu cadastro" } }
    p { "O link vale por #{@expires_in}. Se não foi você quem se cadastrou, ignore esta mensagem." }
  end
end
