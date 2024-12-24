# frozen_string_literal: true

class SyncBlueprint < Blueprinter::Base
  identifier :id

  fields :stream_name, :status, :sync_mode, :schedule_type,
         :sync_frequency, :schema, :supported_sync_modes,
         :source_defined_cursor, :default_cursor_field,
         :source_defined_primary_key, :destination_sync_mode,
         :destination_database_schema, :created_at, :updated_at
end
