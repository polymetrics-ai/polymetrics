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
        process_sync_records(sync_run)
        process_deletions(sync_run)
      end

      def process_sync_records(sync_run)
        sync_run.sync_read_records.find_each(batch_size: 1000) do |sync_read_record|
          process_single_record(sync_run, sync_read_record)
        end
      end

      def process_single_record(sync_run, sync_read_record)
        ActiveRecord::Base.transaction do
          process_record_data(sync_run, sync_read_record)
          mark_record_as_processed(sync_read_record)
        end
      end

      def process_record_data(sync_run, sync_read_record)
        if sync_run.sync.incremental_dedup?
          process_with_dedup(sync_run, sync_read_record)
        else
          create_write_records(sync_read_record)
        end
      end

      def process_with_dedup(sync_run, sync_read_record)
        redis_key = "sync:#{sync_run.sync.id}:transformed:#{sync_read_record.id}"

        Etl::Extractors::ConvertReadRecord::IncrementalDedupService.new(
          sync_run,
          sync_read_record.id,
          redis_key
        ).call
      end

      def mark_record_as_processed(sync_read_record)
        sync_read_record.update!(extraction_completed_at: Time.current)
      end

      def process_deletions(sync_run)
        return unless sync_run.sync.incremental_dedup?

        Etl::Extractors::ConvertReadRecord::ProcessDeletionsService.new(
          sync_run,
          sync_run.sync_read_records.last&.id,
          sync_run.sync_read_records.last&.data
        ).call
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
        return if sync_read_record.data.nil?

        unless sync_read_record.data.is_a?(Array)
          Rails.logger.error "Invalid data format for sync_read_record #{sync_read_record.id}"
          return
        end

        Array(sync_read_record.data).each do |record_data|
          create_single_write_record(sync_read_record, record_data)
        end
      end

      def create_single_write_record(sync_read_record, record_data)
        destination_action = sync_read_record.sync.connection.destination.integration_type == "database" ? :insert : :create

        SyncWriteRecord.create!(
          sync: sync_read_record.sync,
          sync_run: sync_read_record.sync_run,
          sync_read_record: sync_read_record,
          data: record_data,
          destination_action: destination_action
        )
      end
    end
  end
end
