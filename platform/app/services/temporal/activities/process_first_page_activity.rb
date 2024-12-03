# frozen_string_literal: true

module Temporal
  module Activities
    class ProcessFirstPageActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      def execute(sync_run_id:, signal_data:)
        @sync_run = SyncRun.find(sync_run_id)
        @sync = @sync_run.sync
        @workflow_store = ::WorkflowStoreService.new

        workflow_data = fetch_workflow_data(signal_data[:workflow_id])
        page_data = workflow_data[:data]
        total_pages = signal_data[:total_pages]

        process_page_data(page_data, total_pages)

        { status: "success", message: "first page processed", total_pages: total_pages }
      end

      private

      def fetch_workflow_data(workflow_id)
        workflow_key = "#{workflow_id}:1"
        @workflow_store.get_workflow_data(workflow_key)[:result]
      end

      def process_page_data(page_data, total_pages)
        ActiveRecord::Base.transaction do
          create_sync_read_record(page_data)
          initialize_pagination(total_pages)
          update_extraction_stats(page_data)
        end
      end

      def create_sync_read_record(records)
        SyncReadRecord.create!(
          sync_run: @sync_run,
          sync: @sync,
          data: records
        )
      rescue ActiveRecord::RecordInvalid => e
        raise unless e.message.include?("Signature has already been taken")

        activity.logger.info("Skipping duplicate page for sync_id: #{@sync.id}")
      end

      def initialize_pagination(total_pages)
        @sync_run.update!(
          total_pages: total_pages,
          current_page: 1,
          last_extracted_at: Time.current
        )
      end

      def update_extraction_stats(records)
        @sync_run.total_records_read += records.size
        @sync_run.successful_records_read += records.size
        @sync_run.save!
      end

      def extract_cursor_value(record)
        return if @sync.default_cursor_field.blank?

        record[@sync.default_cursor_field.first]
      end
    end
  end
end