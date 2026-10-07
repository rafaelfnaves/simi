class Categories::SuggestionsController < ApplicationController
  def create
    Category.create_suggested_for(Current.user)

    redirect_to categories_path, notice: t("categories.suggestions.flash.created")
  end
end
