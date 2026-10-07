class CategoriesController < ApplicationController
  before_action :set_category, only: %i[ edit update destroy ]

  def index
    render Views::Categories::Index.new(
      roots: Current.user.categories.roots.includes(:subcategories).by_name,
      suggestible: Current.user.categories.none?
    )
  end

  def new
    render Views::Categories::New.new(category: new_category, parents:)
  end

  def create
    category = Current.user.categories.new(attributes)
    category.parent = parent

    if category.save
      redirect_to categories_path, notice: t("categories.flash.saved")
    else
      render Views::Categories::New.new(category:, parents:), status: :unprocessable_content
    end
  end

  def edit
    render Views::Categories::Edit.new(category: @category)
  end

  def update
    if @category.update(attributes)
      redirect_to categories_path, notice: t("categories.flash.saved")
    else
      render Views::Categories::Edit.new(category: @category), status: :unprocessable_content
    end
  end

  def destroy
    if @category.destroy
      redirect_to categories_path, notice: t("categories.flash.destroyed")
    else
      redirect_to categories_path, alert: t("categories.flash.in_use")
    end
  end

  private
    def set_category
      @category = Current.user.categories.find(params[:id])
    end

    def attributes
      action_name == "update" ? update_params : create_params.except(:parent_id)
    end

    def create_params
      params.expect(category: [ :name, :nature, :color, :icon, :parent_id ])
    end

    # Nature is absent on purpose: it is immutable, and a subcategory takes it from
    # its parent rather than from the form.
    def update_params
      params.expect(category: [ :name, :color, :icon ])
    end

    # Resolved inside the person's own categories, so a foreign id is a 404 and
    # never a parent.
    def parent
      id = params.dig(:category, :parent_id).presence || params[:parent_id].presence
      Current.user.categories.find(id) if id
    end

    def new_category
      Current.user.categories.new(
        parent:, nature: parent&.nature || "expense", color: "slate", icon: "other"
      )
    end

    def parents
      Current.user.categories.active.roots.by_name
    end
end
