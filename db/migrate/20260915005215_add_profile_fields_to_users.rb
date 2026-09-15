class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :name, null: false
      t.datetime :confirmed_at
      t.string :theme, null: false, default: "system"
      t.string :time_zone, null: false, default: "America/Sao_Paulo"
      t.string :locale, null: false, default: "pt-BR"
    end
  end
end
