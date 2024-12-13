# frozen_string_literal: true

module Syncs
  class CreateService
    DEFAULT_SYNC_FREQUENCY = "*/30 * * * *"

    def initialize(connection_id)
      @connection = Connection.find(connection_id)
    end

    def call
      schema = fetch_schema
      create_syncs(schema)
    end

    private

    def fetch_schema
      Catalogs::FetchSchemaService.new(@connection.source.connector_class_name).call
    end

    def create_syncs(schema)
      schema.each_key do |stream|
        Sync.create!(
          connection: @connection,
          stream_name: stream,
          status: :queued,
          sync_mode: determine_sync_mode(schema[stream]),
          schedule_type: :manual,
          schema: schema[stream],
          sync_frequency: DEFAULT_SYNC_FREQUENCY,
          supported_sync_modes: schema[stream]["x-supported_sync_modes"],
          source_defined_cursor: schema[stream]["x-source_defined_cursor"] || false,
          default_cursor_field: schema[stream]["x-default_cursor_field"],
          source_defined_primary_key: schema[stream]["x-source_defined_primary_key"]
        )
      end
    end

    def determine_sync_mode(stream)
      supported_modes = stream["x-supported_sync_modes"] || []
      default_mode = stream["x-default_sync_mode"]

      if supported_modes.any? { |mode| mode.to_s.include?("incremental") } && 
         default_mode&.to_s&.include?("incremental")
        :incremental_dedup
      else
        :full_refresh_overwrite
      end
    end
  end
end
