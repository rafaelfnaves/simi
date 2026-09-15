# frozen_string_literal: true

class Views::Registrations::New < Views::AuthBase
  include Phlex::Rails::Helpers::FormAuthenticityToken

  def initialize(user:)
    @user = user
  end

  def view_template
    RubyUI.Form(action: registration_path, method: "post", class: "flex flex-col gap-4") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

      render Components::Field.new(name: :name, label: "Nome", model: @user, scope: "user")
      render Components::Field.new(name: :email_address, label: "E-mail", model: @user, scope: "user", type: :email, autocomplete: "email")
      render Components::Field.new(name: :password, label: "Senha", model: @user, scope: "user", type: :password, autocomplete: "new-password")

      RubyUI.Button(type: "submit", class: "w-full") { "Criar conta" }
    end

    p(class: "text-center text-sm text-muted-foreground") do
      plain "Já tem uma conta? "
      RubyUI.Link(href: new_session_path) { "Entrar" }
    end
  end

  private

  def page_title = "Criar sua conta"

  def page_subtitle = "Organize sua vida financeira em um só lugar."
end
