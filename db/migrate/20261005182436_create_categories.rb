class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :parent, foreign_key: { to_table: :categories, on_delete: :cascade }
      t.string :name, null: false
      t.string :nature, null: false
      t.string :color, null: false
      t.string :icon, null: false
      t.datetime :archived_at

      t.timestamps
    end

    add_index :categories, [ :user_id, :nature, :archived_at ]

    # NULLS NOT DISTINCT is what makes this cover root categories: their parent_id
    # is null, and Postgres would otherwise treat every null as distinct and let
    # two namesake roots through.
    add_index :categories, "user_id, parent_id, nature, lower(name)",
      unique: true, nulls_not_distinct: true, where: "archived_at IS NULL",
      name: "index_categories_on_user_parent_and_active_name"
  end
end
