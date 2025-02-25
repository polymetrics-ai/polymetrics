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

ActiveRecord::Schema[7.1].define(version: 2025_02_01_020527) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "chat_connections", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.bigint "connection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id", "connection_id"], name: "index_chat_connections_on_chat_id_and_connection_id", unique: true
    t.index ["chat_id"], name: "index_chat_connections_on_chat_id"
    t.index ["connection_id"], name: "index_chat_connections_on_connection_id"
  end

  create_table "chats", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "tool_call_data", default: []
    t.string "description", limit: 500
    t.index ["user_id"], name: "index_chats_on_user_id"
    t.index ["workspace_id", "user_id"], name: "index_chats_on_workspace_id_and_user_id"
    t.index ["workspace_id"], name: "index_chats_on_workspace_id"
  end

  create_table "connections", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.bigint "source_id", null: false
    t.bigint "destination_id", null: false
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "configuration", null: false
    t.integer "schedule_type", default: 0, null: false
    t.string "stream_prefix"
    t.string "sync_frequency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "namespace", default: 0
    t.index ["destination_id"], name: "index_connections_on_destination_id"
    t.index ["source_id"], name: "index_connections_on_source_id"
    t.index ["workspace_id", "name"], name: "index_connections_on_workspace_id_and_name", unique: true
    t.index ["workspace_id"], name: "index_connections_on_workspace_id"
  end

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

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.text "content", null: false
    t.integer "role", null: false
    t.integer "message_type", null: false
    t.boolean "answered", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_organizations_on_name", unique: true
  end

  create_table "pipeline_actions", force: :cascade do |t|
    t.bigint "pipeline_id", null: false
    t.bigint "query_action_id"
    t.integer "action_type", null: false
    t.integer "position", null: false
    t.jsonb "action_data", default: {}, null: false
    t.jsonb "result_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pipeline_id", "position"], name: "index_pipeline_actions_on_pipeline_id_and_position", unique: true
    t.index ["pipeline_id"], name: "index_pipeline_actions_on_pipeline_id"
    t.index ["query_action_id"], name: "index_pipeline_actions_on_query_action_id"
  end

  create_table "pipelines", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_pipelines_on_message_id"
  end

  create_table "sync_logs", force: :cascade do |t|
    t.bigint "sync_run_id", null: false
    t.integer "log_type", null: false
    t.text "message"
    t.datetime "emitted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["emitted_at"], name: "index_sync_logs_on_emitted_at"
    t.index ["sync_run_id"], name: "index_sync_logs_on_sync_run_id"
  end

  create_table "sync_read_records", force: :cascade do |t|
    t.bigint "sync_run_id", null: false
    t.bigint "sync_id", null: false
    t.jsonb "data", null: false
    t.string "signature", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "extraction_completed_at"
    t.datetime "transformation_completed_at"
    t.index ["signature", "sync_id"], name: "index_sync_read_records_on_signature_and_sync_id", unique: true
    t.index ["sync_id"], name: "index_sync_read_records_on_sync_id"
    t.index ["sync_run_id"], name: "index_sync_read_records_on_sync_run_id"
  end

  create_table "sync_runs", force: :cascade do |t|
    t.bigint "sync_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.integer "total_records_read", default: 0
    t.integer "total_records_written", default: 0
    t.integer "successful_records_read", default: 0
    t.integer "failed_records_read", default: 0
    t.integer "successful_records_write", default: 0
    t.integer "records_failed_to_write", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_page", default: 0
    t.integer "total_pages", default: 0
    t.integer "current_offset", default: 0
    t.integer "batch_size", default: 1000
    t.string "last_cursor_value"
    t.datetime "last_extracted_at"
    t.boolean "extraction_completed", default: false
    t.integer "records_extracted", default: 0
    t.string "temporal_workflow_id"
    t.string "temporal_run_id"
    t.jsonb "temporal_read_data_workflow_ids", default: []
    t.boolean "transformation_completed", default: false
    t.datetime "last_transformed_at"
    t.index ["status"], name: "index_sync_runs_on_status"
    t.index ["sync_id", "current_page"], name: "index_sync_runs_on_sync_id_and_current_page"
    t.index ["sync_id", "last_cursor_value"], name: "index_sync_runs_on_sync_id_and_last_cursor_value"
    t.index ["sync_id", "last_extracted_at"], name: "index_sync_runs_on_sync_id_and_last_extracted_at"
    t.index ["sync_id", "last_transformed_at"], name: "index_sync_runs_on_sync_id_and_last_transformed_at"
    t.index ["sync_id"], name: "index_sync_runs_on_sync_id"
    t.index ["temporal_read_data_workflow_ids"], name: "index_sync_runs_on_temporal_read_data_workflow_ids", using: :gin
    t.index ["temporal_run_id"], name: "index_sync_runs_on_temporal_run_id"
    t.index ["temporal_workflow_id"], name: "index_sync_runs_on_temporal_workflow_id"
  end

  create_table "sync_write_records", force: :cascade do |t|
    t.bigint "sync_run_id", null: false
    t.bigint "sync_id", null: false
    t.jsonb "data", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "extraction_completed_at"
    t.bigint "sync_read_record_id"
    t.string "primary_key_signature"
    t.string "data_signature"
    t.integer "destination_action", default: 0, null: false
    t.index ["data_signature"], name: "index_sync_write_records_on_data_signature"
    t.index ["primary_key_signature"], name: "index_sync_write_records_on_primary_key_signature"
    t.index ["sync_id"], name: "index_sync_write_records_on_sync_id"
    t.index ["sync_read_record_id"], name: "index_sync_write_records_on_sync_read_record_id"
    t.index ["sync_run_id"], name: "index_sync_write_records_on_sync_run_id"
  end

  create_table "syncs", force: :cascade do |t|
    t.bigint "connection_id", null: false
    t.string "stream_name", null: false
    t.integer "status", default: 0, null: false
    t.integer "sync_mode", null: false
    t.string "sync_frequency", null: false
    t.integer "schedule_type", default: 0, null: false
    t.jsonb "schema"
    t.string "supported_sync_modes", array: true
    t.boolean "source_defined_cursor", default: false, null: false
    t.string "default_cursor_field", array: true
    t.string "source_defined_primary_key", array: true
    t.string "destination_sync_mode"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "destination_database_schema"
    t.index ["connection_id", "stream_name"], name: "index_syncs_on_connection_id_and_stream_name", unique: true
    t.index ["connection_id"], name: "index_syncs_on_connection_id"
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

  add_foreign_key "chat_connections", "chats"
  add_foreign_key "chat_connections", "connections"
  add_foreign_key "chats", "users"
  add_foreign_key "chats", "workspaces"
  add_foreign_key "connections", "connectors", column: "destination_id"
  add_foreign_key "connections", "connectors", column: "source_id"
  add_foreign_key "connections", "workspaces"
  add_foreign_key "connectors", "workspaces"
  add_foreign_key "messages", "chats"
  add_foreign_key "pipeline_actions", "pipeline_actions", column: "query_action_id"
  add_foreign_key "pipeline_actions", "pipelines"
  add_foreign_key "pipelines", "messages"
  add_foreign_key "sync_logs", "sync_runs"
  add_foreign_key "sync_read_records", "sync_runs"
  add_foreign_key "sync_read_records", "syncs"
  add_foreign_key "sync_runs", "syncs"
  add_foreign_key "sync_write_records", "sync_runs"
  add_foreign_key "sync_write_records", "syncs"
  add_foreign_key "syncs", "connections"
  add_foreign_key "user_organization_memberships", "organizations"
  add_foreign_key "user_organization_memberships", "users"
  add_foreign_key "user_workspace_memberships", "users"
  add_foreign_key "user_workspace_memberships", "workspaces"
  add_foreign_key "workspaces", "organizations"
end
