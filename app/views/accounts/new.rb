# frozen_string_literal: true

class Views::Accounts::New < Views::Base
  def initialize(account:)
    @account = account
  end

  def view_template
    render Components::PageHeader.new(title: t(".title"), subtitle: t(".subtitle"))

    RubyUI.Card(class: "p-6 max-w-xl") do
      render Components::AccountForm.new(account: @account, action: accounts_path, kind_editable: true)
    end
  end
end
