# frozen_string_literal: true

class Views::Sessions::New < Views::AuthBase
  include Phlex::Rails::Helpers::FormAuthenticityToken

  def view_template
    RubyUI.Form(action: session_path, method: "post", class: "flex flex-col gap-4") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

      render Components::Field.new(name: :email_address, label: "E-mail", type: :email, autocomplete: "email")
      render Components::Field.new(name: :password, label: "Senha", type: :password, autocomplete: "current-password")

      RubyUI.Button(type: "submit", class: "w-full") { "Entrar" }
    end

    div(class: "flex flex-col gap-1 text-center text-sm text-muted-foreground") do
      RubyUI.Link(href: new_password_path) { "Esqueci minha senha" }
      span do
        plain "Não tem conta? "
        RubyUI.Link(href: new_registration_path) { "Criar agora" }
      end
    end
  end

  private

  def page_title = "Entrar"

  def page_subtitle = "Acesse sua vida financeira."
end
