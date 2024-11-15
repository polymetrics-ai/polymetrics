# frozen_string_literal: true

module Etl
  module Extractors
    class FileExtractorService
      def initialize(sync_run)
        @sync_run = sync_run
        @sync = sync_run.sync
      end

      def call
        # TODO: Implement file extraction logic
        raise NotImplementedError, "File extraction not yet implemented"
      end
    end
  end
end
