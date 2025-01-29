# frozen_string_literal: true

module Syncs
  class CreateService
    DEFAULT_SYNC_FREQUENCY = "*/30 * * * *"

    def initialize(connection_id, streams = nil)
      @connection = Connection.find(connection_id)
      @streams = streams
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
      streams_to_sync = @streams.present? ? schema.slice(*@streams) : schema
      streams_to_sync.each do |stream, stream_schema|
        create_sync_for_stream(stream, stream_schema)
      end
    end

    def create_sync_for_stream(stream, stream_schema)
      sync = build_sync(stream, stream_schema)
      sync.destination_database_schema = generate_destination_schema(sync) if database_destination?
      sync.save!
    end

    def build_sync(stream, stream_schema)
      Sync.new(
        connection: @connection,
        stream_name: stream,
        status: :queued,
        sync_mode: determine_sync_mode(stream_schema),
        schedule_type: :manual,
        schema: stream_schema,
        sync_frequency: DEFAULT_SYNC_FREQUENCY,
        supported_sync_modes: stream_schema["x-supported_sync_modes"],
        source_defined_cursor: stream_schema["x-source_defined_cursor"] || false,
        default_cursor_field: stream_schema["x-default_cursor_field"],
        source_defined_primary_key: stream_schema["x-source_defined_primary_key"]
      )
    end

    def database_destination?
      @connection.destination.integration_type == "database"
    end

    def generate_destination_schema(sync)
      Syncs::DestinationSchemaNormalizerService.new(sync).call
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
