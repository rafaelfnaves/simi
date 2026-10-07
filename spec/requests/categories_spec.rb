require "rails_helper"

RSpec.describe "Categories" do
  let(:user) { create(:user) }

  describe "GET /categories" do
    it "requires a session" do
      get categories_path

      expect(response).to redirect_to(new_session_path)
    end

    it "explains what categories are for and offers the suggested set" do
      sign_in user

      get categories_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("views.categories.index.empty_title"))
      expect(Nokogiri::HTML5(response.body).at_css("form[action='/categories/suggestions']")).to be_present
    end

    it "separates the categories by nature" do
      create(:category, user:, name: "Alimentação", nature: "expense")
      create(:category, user:, name: "Salário", nature: "income")
      sign_in user

      get categories_path

      expect(response.body).to include(
        I18n.t("views.categories.index.expenses"), "Alimentação",
        I18n.t("views.categories.index.incomes"), "Salário"
      )
    end

    it "shows the subcategories under their parent" do
      parent = create(:category, user:, name: "Alimentação")
      create(:category, user:, parent:, name: "Mercado")
      sign_in user

      get categories_path

      expect(response.body).to include("Alimentação", "Mercado")
    end

    it "stops offering the suggested set once a category exists" do
      create(:category, user:)
      sign_in user

      get categories_path

      expect(Nokogiri::HTML5(response.body).at_css("form[action='/categories/suggestions']")).to be_nil
    end

    it "marks the archived ones apart" do
      create(:category, :archived, user:, name: "Lazer antigo")
      sign_in user

      get categories_path

      expect(response.body).to include("Lazer antigo", I18n.t("views.categories.index.archived"))
    end

    it "never shows someone else's categories" do
      create(:category, name: "Categoria alheia")
      sign_in user

      get categories_path

      expect(response.body).not_to include("Categoria alheia")
    end
  end

  describe "POST /categories" do
    before { sign_in user }

    def valid_params(overrides = {})
      { category: { name: "Academia", nature: "expense", color: "rose", icon: "health" }.merge(overrides) }
    end

    it "creates a category with its colour and icon" do
      post categories_path, params: valid_params

      category = user.categories.sole
      expect(category.name).to eq("Academia")
      expect(category.color).to eq("rose")
      expect(category.icon).to eq("health")
      expect(response).to redirect_to(categories_path)
    end

    it "creates a subcategory that inherits the nature of its parent" do
      parent = create(:category, user:, nature: "income")

      post categories_path, params: valid_params(parent_id: parent.id)

      expect(user.categories.find_by(name: "Academia").nature).to eq("income")
    end

    it "refuses a third level" do
      subcategory = create(:category, :subcategory, user:)

      post categories_path, params: valid_params(parent_id: subcategory.id)

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.categories.where(name: "Academia")).to be_empty
    end

    it "refuses a name already taken by a sibling of the same nature" do
      create(:category, user:, name: "Academia", nature: "expense")

      post categories_path, params: valid_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.categories.count).to eq(1)
    end

    it "allows the same name under the other nature" do
      create(:category, user:, name: "Investimentos", nature: "expense")

      post categories_path, params: valid_params(name: "Investimentos", nature: "income")

      expect(user.categories.count).to eq(2)
    end

    it "refuses a colour outside the palette" do
      post categories_path, params: valid_params(color: "chartreuse")

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "refuses an icon outside the catalog" do
      post categories_path, params: valid_params(icon: "bitcoin")

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "answers 404 when the parent belongs to someone else" do
      post categories_path, params: valid_params(parent_id: create(:category).id)

      expect(response).to have_http_status(:not_found)
      expect(user.categories).to be_empty
    end
  end

  describe "GET /categories/:id/edit" do
    before { sign_in user }

    it "opens the person's own category, without offering the nature" do
      category = create(:category, user:, name: "Academia")

      get edit_category_path(category)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Academia")
      expect(Nokogiri::HTML5(response.body).at_css("[name='category[nature]']")).to be_nil
    end

    it "answers 404 for a category that is not theirs" do
      get edit_category_path(create(:category))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /categories/:id" do
    before { sign_in user }

    it "saves the name, colour and icon" do
      category = create(:category, user:, name: "Academia", color: "rose", icon: "health")

      patch category_path(category), params: { category: { name: "Esportes", color: "sky", icon: "leisure" } }

      expect(category.reload).to have_attributes(name: "Esportes", color: "sky", icon: "leisure")
    end

    it "ignores a nature smuggled in through the form" do
      category = create(:category, user:, nature: "expense")

      patch category_path(category), params: { category: { name: "Academia", nature: "income" } }

      expect(category.reload.nature).to eq("expense")
    end

    it "refuses a blank name" do
      category = create(:category, user:, name: "Academia")

      patch category_path(category), params: { category: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(category.reload.name).to eq("Academia")
    end
  end

  describe "DELETE /categories/:id" do
    before { sign_in user }

    it "deletes a category that has no use" do
      category = create(:category, user:)

      expect { delete category_path(category) }.to change { user.categories.count }.by(-1)
    end

    it "refuses while a subcategory hangs from it, and says to archive instead" do
      parent = create(:category, user:)
      create(:category, user:, parent:)

      delete category_path(parent)

      expect(response).to redirect_to(categories_path)
      expect(flash[:alert]).to eq(I18n.t("categories.flash.in_use"))
      expect(parent.reload).to be_persisted
    end
  end
end
