# frozen_string_literal: true

module Etl
  module Extractors
    class DatabaseExtractorService
      def initialize(sync_run)
        @sync_run = sync_run
        @sync = sync_run.sync
      end

      def call
        # TODO: Implement database extraction logic
        raise NotImplementedError, "Database extraction not yet implemented"
      end
    end
  end
end
