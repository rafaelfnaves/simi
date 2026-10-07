class Accounts::ArchivesController < ApplicationController
  before_action :set_account

  def create
    @account.archive!
    redirect_to accounts_path, notice: t("accounts.archives.flash.archived")
  end

  def destroy
    @account.unarchive!
    redirect_to accounts_path, notice: t("accounts.archives.flash.unarchived")
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to accounts_path, alert: t("accounts.archives.flash.name_taken")
  end

  private
    def set_account
      @account = Current.user.accounts.find(params[:account_id])
    end
end
