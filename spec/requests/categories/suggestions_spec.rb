require "rails_helper"

RSpec.describe "Category suggestions" do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /categories/suggestions" do
    it "creates the suggested tree as ordinary categories of the person" do
      post categories_suggestions_path

      expect(user.categories.roots.count).to eq(Category::SUGGESTED.count)
      expect(user.categories.find_by(name: "Alimentação").subcategories.count).to eq(3)
      expect(response).to redirect_to(categories_path)
    end

    it "stops offering itself afterwards" do
      post categories_suggestions_path
      get categories_path

      expect(Nokogiri::HTML5(response.body).at_css("form[action='/categories/suggestions']")).to be_nil
    end

    it "does not duplicate anything when accepted twice" do
      post categories_suggestions_path

      expect { post categories_suggestions_path }.not_to change { user.categories.count }
    end

    it "does not revive what the person archived" do
      post categories_suggestions_path
      lazer = user.categories.find_by(name: "Lazer")
      lazer.archive!

      post categories_suggestions_path

      expect(lazer.reload).to be_archived
    end
  end
end
