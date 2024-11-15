# frozen_string_literal: true

module Etl
  module Extractors
    class DataExtractionService
      def initialize(sync_run)
        @sync_run = sync_run
        @sync = sync_run.sync
        @integration_type = @sync.connection.source.integration_type
      end

      def call
        extractor_service.new(@sync_run).call
      end

      private

      def extractor_service
        case @integration_type
        when "api"
          ::Etl::Extractors::ApiExtractorService
        when "database"
          ::Etl::Extractors::DatabaseExtractorService
        when "file"
          ::Etl::Extractors::FileExtractorService
        else
          raise NotImplementedError, "Unsupported integration type: #{@integration_type}"
        end
      end
    end
  end
end
