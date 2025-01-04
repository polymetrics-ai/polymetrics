# frozen_string_literal: true

module Temporal
  module Activities
    class UpdateWriteRecordsStatusActivity < ::Temporal::Activity
      retry_policy(
        interval: 2,
        backoff: 2,
        max_attempts: 5
      )

      def execute(params)
        params = params.transform_keys(&:to_s)
        write_record_ids = params["write_record_ids"]
        status = params["status"]

        begin
          SyncWriteRecord.where(id: write_record_ids).update_all(
            status: status,
            updated_at: Time.current
          )
          
          { 
            status: "success",
            write_record_ids: write_record_ids,
            updated_status: status
          }
        rescue StandardError => e
          Rails.logger.error("UpdateWriteRecordsStatusActivity failed: #{e.message}")
          {
            status: "error",
            error: e.message,
            write_record_ids: write_record_ids
          }
        end
      end
    end
  end
end 