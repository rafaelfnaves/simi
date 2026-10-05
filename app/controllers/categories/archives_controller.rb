class Categories::ArchivesController < ApplicationController
  ARCHIVED = "Categoria arquivada, junto com suas subcategorias.".freeze
  UNARCHIVED = "Categoria reativada.".freeze
  NAME_TAKEN = "Já existe uma categoria ativa com esse nome. Renomeie uma das duas antes de reativar.".freeze

  before_action :set_category

  def create
    @category.archive!
    redirect_to categories_path, notice: ARCHIVED
  end

  def destroy
    @category.unarchive!
    redirect_to categories_path, notice: UNARCHIVED
  rescue ActiveRecord::RecordInvalid
    redirect_to categories_path, alert: NAME_TAKEN
  end

  private
    def set_category
      @category = Current.user.categories.find(params[:category_id])
    end
end
