class DashboardController < ApplicationController
  def show
    render Views::Dashboard::Show.new
  end
end
