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

        sync_read_records = sync_run.sync_read_records

        return if sync_read_records.empty?

        ActiveRecord::Base.transaction do
          sync_read_records.each do |sync_read_record|
            create_write_records(sync_read_record)
            sync_read_record.update!(extraction_completed_at: Time.current)
          end
        end

        extraction_completed = sync_read_records.all? do |sync_read_record|
          sync_read_record.extraction_completed_at.present?
        end

        sync_run.update!(
          extraction_completed: extraction_completed,
          last_extracted_at: Time.current,
          records_extracted: sync_run.sync_read_records.count
        )

        { extraction_completed: extraction_completed, status: "success" }
      end

      private

      def create_write_records(sync_read_record)
        records = Array(sync_read_record.data)
        records.each do |record_data|
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
end
