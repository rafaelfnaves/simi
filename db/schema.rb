# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_05_182436) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "archived_at"
    t.decimal "balance", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "institution"
    t.string "name", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index "user_id, lower((name)::text)", name: "index_accounts_on_user_and_active_name", unique: true, where: "(archived_at IS NULL)"
    t.index ["user_id", "type", "archived_at"], name: "index_accounts_on_user_id_and_type_and_archived_at"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.string "icon", null: false
    t.string "name", null: false
    t.string "nature", null: false
    t.bigint "parent_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index "user_id, parent_id, nature, lower((name)::text)", name: "index_categories_on_user_parent_and_active_name", unique: true, where: "(archived_at IS NULL)", nulls_not_distinct: true
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["user_id", "nature", "archived_at"], name: "index_categories_on_user_id_and_nature_and_archived_at"
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "locale", default: "pt-BR", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "theme", default: "system", null: false
    t.string "time_zone", default: "America/Sao_Paulo", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "accounts", "users", on_delete: :cascade
  add_foreign_key "categories", "categories", column: "parent_id", on_delete: :cascade
  add_foreign_key "categories", "users", on_delete: :cascade
  add_foreign_key "sessions", "users"
end
