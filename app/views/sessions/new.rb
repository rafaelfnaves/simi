# frozen_string_literal: true

class Views::Sessions::New < Views::AuthBase
  include Phlex::Rails::Helpers::FormAuthenticityToken

  def view_template
    RubyUI.Form(action: session_path, method: "post", class: "flex flex-col gap-4") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

      render Components::Field.new(name: :email_address, label: User.human_attribute_name(:email_address), type: :email, autocomplete: "email")
      render Components::Field.new(name: :password, label: User.human_attribute_name(:password), type: :password, autocomplete: "current-password")

      RubyUI.Button(type: "submit", class: "w-full") { t(".submit") }
    end

    div(class: "flex flex-col gap-1 text-center text-sm text-muted-foreground") do
      RubyUI.Link(href: new_password_path) { t(".forgot") }
      span do
        plain t(".no_account")
        RubyUI.Link(href: new_registration_path) { t(".sign_up") }
      end
    end
  end

  private

  def page_title = t(".title")

  def page_subtitle = t(".subtitle")
end
