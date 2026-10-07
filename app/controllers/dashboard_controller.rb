class DashboardController < ApplicationController
  def show
    render Views::Dashboard::Show.new(consolidated_balance:)
  end

  private
    # nil while nothing holds money, so the block can keep its empty state instead
    # of showing a zero that reads as a real balance.
    def consolidated_balance
      deposits = Current.user.accounts.deposits.active

      deposits.sum(:balance) if deposits.exists?
    end
end
