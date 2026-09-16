# frozen_string_literal: true

class Views::Settings::Profiles::Show < Views::Base
  include Phlex::Rails::Helpers::FormAuthenticityToken

  THEME_LABELS = { "system" => "Seguir o sistema", "light" => "Claro", "dark" => "Escuro" }.freeze

  def initialize(user:)
    @user = user
  end

  def view_template
    render Components::PageHeader.new(title: "Perfil", subtitle: "Seus dados e preferências.")

    RubyUI.Card(class: "p-6 max-w-xl") do
      RubyUI.Form(action: settings_profile_path, method: "post", class: "flex flex-col gap-4") do
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
        input(type: "hidden", name: "_method", value: "patch")

        render Components::Field.new(name: :name, label: "Nome", model: @user, scope: "user")
        email_field
        time_zone_field
        theme_field

        RubyUI.Button(type: "submit", class: "self-start") { "Salvar" }
      end
    end

    p(class: "text-sm text-muted-foreground") do
      plain "Quer trocar a senha? "
      RubyUI.Link(href: new_password_path) { "Enviar link de redefinição" }
    end
  end

  private

  def email_field
    RubyUI.FormField do
      RubyUI.FormFieldLabel(for: "profile_email") { "E-mail" }
      RubyUI.Input(id: "profile_email", value: @user.email_address, disabled: true, readonly: true)
      RubyUI.FormFieldHint { "O e-mail é o identificador da conta e não pode ser alterado aqui." }
    end
  end

  def time_zone_field
    RubyUI.FormField do
      RubyUI.FormFieldLabel(for: "user_time_zone") { "Fuso horário" }
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
      RubyUI.FormFieldLabel(for: "user_theme") { "Tema" }
      select(id: "user_theme", name: "user[theme]", class: select_classes) do
        User::THEMES.each do |theme|
          option(value: theme, selected: theme == @user.theme) { THEME_LABELS.fetch(theme) }
        end
      end
    end
  end

  def select_classes
    "flex h-9 w-full rounded-md border border-border bg-background px-3 py-1 text-sm shadow-xs"
  end
end
