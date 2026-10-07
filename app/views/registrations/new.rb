# frozen_string_literal: true

class Views::Registrations::New < Views::AuthBase
  include Phlex::Rails::Helpers::FormAuthenticityToken

  def initialize(user:)
    @user = user
  end

  def view_template
    RubyUI.Form(action: registration_path, method: "post", class: "flex flex-col gap-4") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

      render Components::Field.new(name: :name, label: User.human_attribute_name(:name), model: @user, scope: "user")
      render Components::Field.new(name: :email_address, label: User.human_attribute_name(:email_address), model: @user, scope: "user", type: :email, autocomplete: "email")
      render Components::Field.new(name: :password, label: User.human_attribute_name(:password), model: @user, scope: "user", type: :password, autocomplete: "new-password")

      RubyUI.Button(type: "submit", class: "w-full") { t(".submit") }
    end

    p(class: "text-center text-sm text-muted-foreground") do
      plain t(".has_account")
      RubyUI.Link(href: new_session_path) { t(".sign_in") }
    end
  end

  private

  def page_title = t(".title")

  def page_subtitle = t(".subtitle")
end
