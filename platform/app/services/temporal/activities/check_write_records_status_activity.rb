# frozen_string_literal: true

module Temporal
  module Activities
    class CheckWriteRecordsStatusActivity < ::Temporal::Activity
      def execute(params)
        params = params.transform_keys(&:to_s)
        sync_run = SyncRun.find(params["sync_run_id"])

        total_records = sync_run.sync_write_records.count
        processed_records = sync_run.sync_write_records.where(status: %i[written failed]).count

        {
          completed: total_records == processed_records,
          total_records: total_records,
          processed_records: processed_records
        }
      end
    end
  end
end
