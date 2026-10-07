# frozen_string_literal: true

class Views::Settings::Profiles::Show < Views::Base
  include Phlex::Rails::Helpers::FormAuthenticityToken

  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::PageHeader.new(title: t(".title"), subtitle: t(".subtitle"))

    RubyUI.Card(class: "p-6 max-w-xl") do
      RubyUI.Form(action: settings_profile_path, method: "post", class: "flex flex-col gap-4") do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        input(type: "hidden", name: "_method", value: "patch")

        render Components::Field.new(
          name: :name, label: User.human_attribute_name(:name), model: @user, scope: "user"
        )
        email_field
        time_zone_field
        theme_field

        RubyUI.Button(type: "submit", class: "self-start") { t(".submit") }
      end
    end

    p(class: "text-sm text-muted-foreground") do
      plain t(".change_password_prompt")
      RubyUI.Link(href: new_password_path) { t(".change_password_link") }
    end
  end

  private

  def email_field
    RubyUI.FormField do
      RubyUI.FormFieldLabel(for: "profile_email") { User.human_attribute_name(:email_address) }
      RubyUI.Input(id: "profile_email", value: @user.email_address, disabled: true, readonly: true)
      RubyUI.FormFieldHint { t(".email_hint") }
    end
  end

  def time_zone_field
    RubyUI.FormField do
      RubyUI.FormFieldLabel(for: "user_time_zone") { User.human_attribute_name(:time_zone) }
      select(id: "user_time_zone", name: "user[time_zone]", class: select_classes) do
        User::TIME_ZONES.sort.each do |zone|
          option(value: zone, selected: zone == @user.time_zone) { zone }
        end
      end
      RubyUI.FormFieldError { @user.errors[:time_zone].to_sentence } if @user.errors[:time_zone].any?
    end
  end

  def theme_field
    RubyUI.FormField do
      RubyUI.FormFieldLabel(for: "user_theme") { User.human_attribute_name(:theme) }
      select(id: "user_theme", name: "user[theme]", class: select_classes) do
        User::THEMES.each do |theme|
          option(value: theme, selected: theme == @user.theme) { User.human_theme(theme) }
        end
      end
    end
  end

  def select_classes
    "flex h-9 w-full rounded-md border border-border bg-background px-3 py-1 text-sm shadow-xs"
  end
end
