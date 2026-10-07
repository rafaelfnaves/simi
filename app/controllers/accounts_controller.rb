class AccountsController < ApplicationController
  before_action :set_account, only: %i[ edit update destroy ]

  def index
    render Views::Accounts::Index.new(accounts: Current.user.accounts.by_name)
  end

  def new
    render Views::Accounts::New.new(account: Accounts::Checking.new(balance: 0))
  end

  def create
    klass = Account.class_for(account_params[:kind])
    account = (klass || Accounts::Checking).new(attributes.merge(user: Current.user))

    if klass && account.save
      redirect_to accounts_path, notice: t("accounts.flash.saved")
    else
      account.errors.add(:kind, :inclusion) unless klass
      render Views::Accounts::New.new(account:), status: :unprocessable_content
    end
  end

  def edit
    render Views::Accounts::Edit.new(account: @account)
  end

  def update
    if @account.update(attributes)
      redirect_to accounts_path, notice: t("accounts.flash.saved")
    else
      render Views::Accounts::Edit.new(account: @account), status: :unprocessable_content
    end
  end

  def destroy
    if @account.destroy
      redirect_to accounts_path, notice: t("accounts.flash.destroyed")
    else
      redirect_to accounts_path, alert: t("accounts.flash.in_use")
    end
  end

  private
    def set_account
      @account = Current.user.accounts.find(params[:id])
    end

    # `kind` is read and dropped rather than assigned: the subclass comes from
    # Account::KINDS, so the browser cannot name the class it instantiates.
    def account_params
      params.expect(account: [ :name, :institution, :balance, :kind ])
    end

    def attributes
      account_params.except(:kind)
    end
end
