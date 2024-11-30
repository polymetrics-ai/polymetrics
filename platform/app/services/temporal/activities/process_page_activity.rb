# frozen_string_literal: true

module Temporal
  module Activities
    class ProcessPageActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      def execute(sync_run_id:, signal_data:, page_number:)
        @sync_run = SyncRun.find(sync_run_id)
        @sync = @sync_run.sync
        @workflow_store = ::WorkflowStoreService.new
        
        @sync_run.with_lock do
          workflow_data = @workflow_store.get_workflow_data(signal_data[:workflow_id])
          result = workflow_data[:result]
          page_data = result[:data]

          ActiveRecord::Base.transaction do
            create_sync_read_record(page_data)
            update_current_page(page_number)
            update_extraction_stats(page_data)
          end
        end
        
        { status: 'success' }
      end

      private

      def create_sync_read_record(records)
        SyncReadRecord.create!(
          sync_run: @sync_run,
          sync: @sync,
          data: records,
          signature: generate_signature(records)
        )
      rescue ActiveRecord::RecordInvalid => e
        raise unless e.message.include?("Signature has already been taken")
        activity.logger.info("Skipping duplicate page for sync_id: #{@sync.id}")
      end

      def update_current_page(page_number)
        @sync_run.update!(
          current_page: page_number,
          last_extracted_at: Time.current
        )
      end

      def update_extraction_stats(records)
        @sync_run.increment!(:total_records_read, records.size)
        @sync_run.increment!(:successful_records_read, records.size)
      end

      def update_cursor(last_record)
        return unless @sync.default_cursor_field.present?
        
        @sync_run.update!(
          last_cursor_value: extract_cursor_value(last_record),
          last_extracted_at: Time.current
        )
      end

      def extract_cursor_value(record)
        return unless @sync.default_cursor_field.present?
        record[@sync.default_cursor_field.first]
      end

      def generate_signature(records)
        Digest::MD5.hexdigest(records.to_json)
      end
    end
  end
end 