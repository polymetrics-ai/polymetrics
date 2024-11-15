# frozen_string_literal: true

module Temporal
  module Activities
    class ExtractDataActivity < ::Temporal::Activity
      def execute(sync_run_id)
        @sync_run = SyncRun.find(sync_run_id)

        begin
          ::Etl::Extractors::DataExtractionService.new(@sync_run).call
          @sync_run.succeeded!
        rescue StandardError => e
          @sync_run.failed!
          raise e
        end
      end
    end
  end
end
