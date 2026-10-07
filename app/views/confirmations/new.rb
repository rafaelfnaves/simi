# frozen_string_literal: true

class Views::Confirmations::New < Views::AuthBase
  include Phlex::Rails::Helpers::FormAuthenticityToken

  def view_template
    RubyUI.Form(action: confirmations_path, method: "post", class: "flex flex-col gap-4") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)

      render Components::Field.new(name: :email_address, label: User.human_attribute_name(:email_address), type: :email, autocomplete: "email")

      RubyUI.Button(type: "submit", class: "w-full") { t(".submit") }
    end

    p(class: "text-center text-sm text-muted-foreground") do
      RubyUI.Link(href: new_session_path) { t(".back") }
    end
  end

  private

  def page_title = t(".title")

  def page_subtitle = t(".subtitle")
end
