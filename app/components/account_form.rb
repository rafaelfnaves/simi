# frozen_string_literal: true

class Components::AccountForm < Components::Base
  include Phlex::Rails::Helpers::FormAuthenticityToken

  # @param kind_editable [Boolean] false on an edit: changing the subclass of a
  #   record would change what the object is, so a wrong kind is deleted and
  #   cadastrada de novo
  def initialize(account:, action:, method: nil, kind_editable: false)
    @account = account
    @action = action
    @method = method
    @kind_editable = kind_editable
  end

  def view_template
    RubyUI.Form(action: @action, method: "post", class: "flex flex-col gap-4") do
      input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
      input(type: "hidden", name: "_method", value: @method) if @method

      kind_field if @kind_editable
      render Components::Field.new(name: :name, label: "Nome", model: @account, scope: "account")
      render Components::Field.new(
        name: :institution, label: "Instituição", model: @account, scope: "account"
      )
      balance_field

      div(class: "flex items-center gap-3") do
        RubyUI.Button(type: "submit") { "Salvar" }
        RubyUI.Link(href: accounts_path) { "Cancelar" }
      end
    end
  end

  private

  def kind_field
    render Components::SelectField.new(
      name: :kind, label: "Tipo", scope: "account", model: @account,
      selected: @account.kind, options: Account::KIND_LABELS.to_a
    )
  end

  def balance_field
    RubyUI.FormField do
      RubyUI.FormFieldLabel(for: "account_balance") { "Saldo atual" }
      RubyUI.Input(
        id: "account_balance", name: "account[balance]", value: formatted_balance,
        inputmode: "decimal", placeholder: "0,00"
      )
      RubyUI.FormFieldHint { "Use vírgula para os centavos. Saldo negativo é aceito." }
      RubyUI.FormFieldError { @account.errors[:balance].to_sentence } if @account.errors[:balance].any?
    end
  end

  def formatted_balance
    raw = @account.balance_before_type_cast
    return raw if raw.is_a?(String)

    @account.balance&.to_s("F")&.tr(".", ",")
  end
end
