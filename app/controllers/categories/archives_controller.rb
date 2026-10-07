class Categories::ArchivesController < ApplicationController
  before_action :set_category

  def create
    @category.archive!
    redirect_to categories_path, notice: t("categories.archives.flash.archived")
  end

  def destroy
    @category.unarchive!
    redirect_to categories_path, notice: t("categories.archives.flash.unarchived")
  rescue ActiveRecord::RecordInvalid
    redirect_to categories_path, alert: t("categories.archives.flash.name_taken")
  end

  private
    def set_category
      @category = Current.user.categories.find(params[:category_id])
    end
end
