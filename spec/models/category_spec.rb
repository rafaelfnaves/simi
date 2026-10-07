require "rails_helper"

RSpec.describe Category do
  describe "validations" do
    it "requires a name" do
      expect(build(:category, name: " ")).not_to be_valid
    end

    it "refuses a colour outside the palette" do
      expect(build(:category, color: "chartreuse")).not_to be_valid
    end

    it "refuses an icon outside the catalog" do
      expect(build(:category, icon: "bitcoin")).not_to be_valid
    end

    it "refuses a nature the product does not have" do
      category = build(:category)
      category.nature = "transfer"

      expect(category).not_to be_valid
      expect(category.errors[:nature]).to be_present
    end

    it "refuses a parent that belongs to someone else" do
      category = build(:category, user: create(:user), parent: create(:category))

      expect(category).not_to be_valid
      expect(category.errors[:parent_id]).to be_present
    end
  end

  describe "the tree" do
    it "inherits the nature of its parent" do
      parent = create(:category, :income)
      child = create(:category, user: parent.user, parent:, nature: "expense")

      expect(child.nature).to eq("income")
    end

    it "stops at two levels" do
      child = create(:category, :subcategory)
      grandchild = build(:category, user: child.user, parent: child)

      expect(grandchild).not_to be_valid
      expect(grandchild.errors[:parent_id])
        .to include(I18n.t("activerecord.errors.models.category.attributes.parent_id.too_deep"))
    end

    it "knows a root from a subcategory" do
      expect(create(:category)).to be_root
      expect(create(:category, :subcategory)).not_to be_root
    end
  end

  describe "name uniqueness" do
    it "refuses two sibling roots with the same name and nature" do
      user = create(:user)
      create(:category, user:, name: "Alimentação")

      expect(build(:category, user:, name: "alimentação")).not_to be_valid
    end

    it "holds that invariant in the database, where a null parent_id would slip through" do
      user = create(:user)
      create(:category, user:, name: "Alimentação")
      duplicate = build(:category, user:, name: "Alimentação")

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows the same name under two different natures" do
      user = create(:user)
      create(:category, user:, name: "Investimentos", nature: "expense")

      expect(build(:category, user:, name: "Investimentos", nature: "income")).to be_valid
    end

    it "allows the same name under two different parents" do
      user = create(:user)
      first = create(:category, user:)
      second = create(:category, user:)
      create(:category, user:, parent: first, name: "Mercado")

      expect(build(:category, user:, parent: second, name: "Mercado")).to be_valid
    end

    it "allows reusing the name of an archived category" do
      user = create(:user)
      create(:category, :archived, user:, name: "Lazer")

      expect(build(:category, user:, name: "Lazer")).to be_valid
    end
  end

  describe "nature" do
    it "cannot change after creation, because it would invert everything below it" do
      category = create(:category, nature: "expense")

      category.nature = "income"

      expect(category).not_to be_valid
      expect(category.errors[:nature])
        .to include(I18n.t("activerecord.errors.models.category.attributes.nature.immutable"))
    end
  end

  describe "archiving" do
    it "takes the subcategories down with it, so no branch is left orphaned" do
      parent = create(:category)
      child = create(:category, user: parent.user, parent:)

      parent.archive!

      expect(parent.reload).to be_archived
      expect(child.reload).to be_archived
    end

    it "leaves the subcategories alone when the parent comes back" do
      parent = create(:category)
      child = create(:category, user: parent.user, parent:)
      parent.archive!

      parent.unarchive!

      expect(parent.reload).to be_active
      expect(child.reload).to be_archived
    end

    it "is idempotent" do
      category = create(:category)
      category.archive!
      archived_at = category.reload.archived_at

      category.archive!

      expect(category.reload.archived_at).to eq(archived_at)
    end
  end

  describe "deleting" do
    it "is allowed while the category has no use" do
      category = create(:category)

      expect { category.destroy }.to change(described_class, :count).by(-1)
    end

    it "is refused while a subcategory hangs from it, archived or not" do
      parent = create(:category)
      child = create(:category, user: parent.user, parent:)
      child.archive!

      expect(parent.destroy).to be(false)
      expect(parent.errors[:base]).to be_present
    end
  end

  describe ".create_suggested_for" do
    let(:user) { create(:user) }

    it "creates the whole suggested tree" do
      expect { described_class.create_suggested_for(user) }
        .to change { user.categories.count }.from(0).to(17)

      expect(user.categories.roots.count).to eq(12)
      expect(user.categories.roots.find_by(name: "Alimentação").subcategories.pluck(:name))
        .to match_array([ "Mercado", "Restaurantes", "Delivery" ])
    end

    it "covers both natures" do
      described_class.create_suggested_for(user)

      expect(user.categories.expense).to be_any
      expect(user.categories.income).to be_any
    end

    it "creates ordinary categories, with no mark of origin" do
      described_class.create_suggested_for(user)
      category = user.categories.roots.first

      expect(category.update(name: "Outro nome")).to be(true)
      expect(category).to be_active
    end

    it "does not duplicate when accepted twice" do
      described_class.create_suggested_for(user)

      expect { described_class.create_suggested_for(user) }.not_to change { user.categories.count }
    end

    it "does not revive what the person archived" do
      described_class.create_suggested_for(user)
      lazer = user.categories.find_by(name: "Lazer")
      lazer.archive!

      described_class.create_suggested_for(user)

      expect(lazer.reload).to be_archived
      expect(user.categories.where(name: "Lazer").count).to eq(1)
    end

    it "every suggested icon and colour is one the product can render" do
      expect(described_class::SUGGESTED.map { |entry| entry[:icon] }.uniq).to all(be_in(described_class::ICONS))
      expect(described_class::SUGGESTED.map { |entry| entry[:color] }.uniq).to all(be_in(described_class::COLORS.keys))
    end
  end

  describe "scoping to a user" do
    it "is destroyed with its owner" do
      user = create(:user)
      create(:category, user:)

      expect { user.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
