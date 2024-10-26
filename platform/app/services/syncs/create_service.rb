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
          sync_frequency: DEFAULT_SYNC_FREQUENCY,
          supported_sync_modes: schema[stream]["supported_sync_modes"]
        )
      end
    end

    def determine_sync_mode(stream)
      if stream["supported_sync_modes"]&.include?("incremental")
        :incremental_append
      else
        :full_refresh_overwrite
      end
    end
  end
end
