class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string  :type, null: false
      t.string  :name, null: false
      t.string  :institution
      t.decimal :balance, precision: 15, scale: 2, null: false, default: 0
      t.datetime :archived_at

      t.timestamps
    end

    add_index :accounts, [ :user_id, :type, :archived_at ]
    add_index :accounts, "user_id, lower(name)",
      unique: true, where: "archived_at IS NULL", name: "index_accounts_on_user_and_active_name"
  end
end
