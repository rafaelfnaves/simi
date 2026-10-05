class Accounts::ArchivesController < ApplicationController
  ARCHIVED = "Conta arquivada.".freeze
  UNARCHIVED = "Conta reativada.".freeze
  NAME_TAKEN = "Já existe uma conta ativa com esse nome. Renomeie uma das duas antes de reativar.".freeze

  before_action :set_account

  def create
    @account.archive!
    redirect_to accounts_path, notice: ARCHIVED
  end

  def destroy
    @account.unarchive!
    redirect_to accounts_path, notice: UNARCHIVED
  rescue ActiveRecord::RecordInvalid
    redirect_to accounts_path, alert: NAME_TAKEN
  end

  private
    def set_account
      @account = Current.user.accounts.find(params[:account_id])
    end
end
