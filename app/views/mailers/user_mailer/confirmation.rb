# frozen_string_literal: true

class Views::Mailers::UserMailer::Confirmation < Components::Base
  def initialize(user:, url:)
    @user = user
    @url = url
  end

  def view_template
    p { "Olá, #{@user.name}." }
    p { "Confirme seu cadastro no SIMI para começar a usar sua conta." }
    p { a(href: @url) { "Confirmar meu cadastro" } }
    p { "O link vale por 24 horas. Se não foi você quem se cadastrou, ignore esta mensagem." }
  end
end
