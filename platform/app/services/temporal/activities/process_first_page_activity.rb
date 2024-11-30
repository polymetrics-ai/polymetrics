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
        
        workflow_data = @workflow_store.get_workflow_data(signal_data[:workflow_id])
        result = workflow_data[:result]
        page_data = result[:data]
        total_pages = result[:total_pages]

        ActiveRecord::Base.transaction do
          create_sync_read_record(page_data)
          initialize_pagination(total_pages)
          update_extraction_stats(page_data)
        end

        { status: 'success', message: 'first page processed', total_pages: total_pages }
      end

      private

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
        @sync_run.increment!(:total_records_read, records.size)
        @sync_run.increment!(:successful_records_read, records.size)
      end

      def extract_cursor_value(record)
        return unless @sync.default_cursor_field.present?
        record[@sync.default_cursor_field.first]
      end
    end
  end
end 