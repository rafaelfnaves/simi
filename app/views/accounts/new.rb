# frozen_string_literal: true

class Views::Accounts::New < Views::Base
  def initialize(account:)
    @account = account
  end

  def view_template
    render Components::PageHeader.new(title: "Nova conta", subtitle: "Onde esse dinheiro fica.")

    RubyUI.Card(class: "p-6 max-w-xl") do
      render Components::AccountForm.new(account: @account, action: accounts_path, kind_editable: true)
    end
  end
end
