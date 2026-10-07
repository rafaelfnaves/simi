require "rails_helper"

RSpec.describe "Category archives" do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /categories/:category_id/archive" do
    it "archives the subcategories along with the parent" do
      parent = create(:category, user:)
      child = create(:category, user:, parent:)

      post category_archive_path(parent)

      expect(parent.reload).to be_archived
      expect(child.reload).to be_archived
      expect(response).to redirect_to(categories_path)
    end

    it "answers 404 for a category that is not theirs" do
      other = create(:category)

      post category_archive_path(other)

      expect(response).to have_http_status(:not_found)
      expect(other.reload).to be_active
    end
  end

  describe "DELETE /categories/:category_id/archive" do
    it "brings the category back without touching its subcategories" do
      parent = create(:category, user:)
      child = create(:category, user:, parent:)
      parent.archive!

      delete category_archive_path(parent)

      expect(parent.reload).to be_active
      expect(child.reload).to be_archived
    end

    it "asks for the parent first when the subcategory's parent is archived" do
      parent = create(:category, user:)
      child = create(:category, user:, parent:)
      parent.archive!

      delete category_archive_path(child)

      expect(response).to redirect_to(categories_path)
      expect(flash[:alert]).to eq(I18n.t("categories.archives.flash.parent_archived"))
      expect(child.reload).to be_archived
    end

    it "refuses with a message when a concurrent request takes the name first" do
      category = create(:category, user:)
      category.archive!
      allow_any_instance_of(Category).to receive(:unarchive!).and_raise(ActiveRecord::RecordNotUnique)

      delete category_archive_path(category)

      expect(response).to redirect_to(categories_path)
      expect(flash[:alert]).to eq(I18n.t("categories.archives.flash.name_taken"))
    end
  end
end
