class Categories::ArchivesController < ApplicationController
  before_action :set_category

  def create
    @category.archive!
    redirect_to categories_path, notice: t("categories.archives.flash.archived")
  end

  def destroy
    @category.unarchive!
    redirect_to categories_path, notice: t("categories.archives.flash.unarchived")
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to categories_path, alert: t("categories.archives.flash.#{unarchive_refusal}")
  end

  private
    def set_category
      @category = Current.user.categories.find(params[:category_id])
    end

    def unarchive_refusal
      @category.errors.added?(:parent_id, :archived) ? "parent_archived" : "name_taken"
    end
end
