# frozen_string_literal: true

module Temporal
  module Activities
    class ConvertReadRecordActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 1,
        max_attempts: 3
      )

      def execute(sync_run_id)
        sync_run = SyncRun.find(sync_run_id)
        return if sync_run.extraction_completed
        return if sync_run.sync_read_records.empty?

        process_read_records(sync_run)
        update_sync_run_status(sync_run)
      end

      private

      def process_read_records(sync_run)
        ActiveRecord::Base.transaction do
          sync_run.sync_read_records.each do |sync_read_record|
            create_write_records(sync_read_record)
            sync_read_record.update!(extraction_completed_at: Time.current)
          end
        end
      end

      def update_sync_run_status(sync_run)
        extraction_completed = all_records_extracted?(sync_run.sync_read_records)

        sync_run.update!(
          extraction_completed: extraction_completed,
          last_extracted_at: Time.current,
          records_extracted: sync_run.sync_read_records.count
        )

        { extraction_completed: extraction_completed, status: "success" }
      end

      def all_records_extracted?(sync_read_records)
        sync_read_records.all? { |record| record.extraction_completed_at.present? }
      end

      def create_write_records(sync_read_record)
        Array(sync_read_record.data).each do |record_data|
          create_single_write_record(sync_read_record, record_data)
        end
      end

      def create_single_write_record(sync_read_record, record_data)
        SyncWriteRecord.create!(
          sync: sync_read_record.sync,
          sync_run: sync_read_record.sync_run,
          sync_read_record: sync_read_record,
          data: record_data
        )
      end
    end
  end
end
