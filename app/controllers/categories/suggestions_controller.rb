class Categories::SuggestionsController < ApplicationController
  CREATED = "Categorias sugeridas criadas. Edite, arquive ou exclua o que não usar.".freeze

  def create
    Category.create_suggested_for(Current.user)

    redirect_to categories_path, notice: CREATED
  end
end
