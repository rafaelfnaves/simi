# frozen_string_literal: true

class Views::Confirmations::New < Views::AuthBase
  include Phlex::Rails::Helpers::FormAuthenticityToken

  def view_template
    RubyUI.Form(action: confirmations_path, method: "post", class: "flex flex-col gap-4") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

      render Components::Field.new(name: :email_address, label: "E-mail", type: :email, autocomplete: "email")

      RubyUI.Button(type: "submit", class: "w-full") { "Enviar novo link" }
    end

    p(class: "text-center text-sm text-muted-foreground") do
      RubyUI.Link(href: new_session_path) { "Voltar para a entrada" }
    end
  end

  private

  def page_title = "Confirmar cadastro"

  def page_subtitle = "Informe seu e-mail e enviaremos um novo link de confirmação."
end
