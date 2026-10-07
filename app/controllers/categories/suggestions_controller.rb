class Categories::SuggestionsController < ApplicationController
  def create
    create_suggestions
    redirect_to categories_path, notice: t("categories.suggestions.flash.created")
  end

  private
    # A double click sends two requests; the one that loses the race on the unique
    # index finds the set already created by the other, which is the outcome asked for.
    def create_suggestions
      Category.create_suggested_for(Current.user)
    rescue ActiveRecord::RecordNotUnique
    end
end
