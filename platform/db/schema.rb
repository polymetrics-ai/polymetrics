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

ActiveRecord::Schema[7.1].define(version: 2024_09_28_074459) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "connectors", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.integer "connector_language"
    t.jsonb "configuration"
    t.string "name"
    t.string "connector_class_name"
    t.string "description"
    t.boolean "connected", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "default_analytics_db", default: false, null: false
    t.integer "integration_type", default: 0, null: false
    t.index ["workspace_id", "name", "configuration"], name: "index_connectors_on_workspace_name_config", unique: true
    t.index ["workspace_id"], name: "index_connectors_on_workspace_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_organizations_on_name", unique: true
  end

  create_table "user_organization_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_user_organization_memberships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_user_org_memberships_on_user_id_and_org_id", unique: true
    t.index ["user_id"], name: "index_user_organization_memberships_on_user_id"
  end

  create_table "user_workspace_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "workspace_id"], name: "index_user_workspace_memberships_on_user_id_and_workspace_id", unique: true
    t.index ["user_id"], name: "index_user_workspace_memberships_on_user_id"
    t.index ["workspace_id"], name: "index_user_workspace_memberships_on_workspace_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.json "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "organization_name"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email", "provider"], name: "index_users_on_email_and_provider", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_name"], name: "index_users_on_organization_name"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  create_table "workspaces", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "organization_id"], name: "index_workspaces_on_name_and_organization_id", unique: true
    t.index ["organization_id"], name: "index_workspaces_on_organization_id"
  end

  add_foreign_key "connectors", "workspaces"
  add_foreign_key "user_organization_memberships", "organizations"
  add_foreign_key "user_organization_memberships", "users"
  add_foreign_key "user_workspace_memberships", "users"
  add_foreign_key "user_workspace_memberships", "workspaces"
  add_foreign_key "workspaces", "organizations"
end
