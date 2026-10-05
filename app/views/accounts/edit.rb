# frozen_string_literal: true

class Views::Accounts::Edit < Views::Base
  def initialize(account:)
    @account = account
  end

  def view_template
    render Components::PageHeader.new(title: "Editar conta", subtitle: @account.name)

    RubyUI.Card(class: "p-6 max-w-xl") do
      render Components::AccountForm.new(
        account: @account, action: account_path(@account), method: "patch"
      )
    end
  end
end
