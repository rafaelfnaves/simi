# frozen_string_literal: true

class Views::Passwords::Edit < Views::AuthBase
  include Phlex::Rails::Helpers::FormAuthenticityToken

  def initialize(user:, token:)
    @user = user
    @token = token
  end

  def view_template
    RubyUI.Form(action: password_path(@token), method: "post", class: "flex flex-col gap-4") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
      input(type: "hidden", name: "_method", value: "patch")

      render Components::Field.new(name: :password, label: "Nova senha", model: @user, type: :password, autocomplete: "new-password")
      render Components::Field.new(name: :password_confirmation, label: "Repita a nova senha", type: :password, autocomplete: "new-password")

      RubyUI.Button(type: "submit", class: "w-full") { "Salvar nova senha" }
    end
  end

  private

  def page_title = "Escolher nova senha"
end
