# frozen_string_literal: true

module Temporal
  module Activities
    class ProcessPageActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      # Add timeouts
      timeouts(
        start_to_close: 600,  # 10 minutes
        heartbeat: 120,       # 2 minutes
        schedule_to_close: 1800 # 30 minutes
      )

      # rubocop:disable Metrics/MethodLength
      def execute(sync_run_id:, signal_data:, pages:)
        initialize_dependencies(sync_run_id)
        processed_pages = Set.new

        Parallel.each(pages, in_threads: 10) do |page_number|
          ActiveRecord::Base.connection_pool.with_connection do
            process_workflow_data(signal_data, page_number)
            processed_pages.add(page_number)

            # Heartbeat after each successful page processing
            activity.heartbeat
          rescue StandardError => e
            handle_page_error(page_number, e)
          ensure
            ActiveRecord::Base.connection_pool.release_connection
          end
        end

        {
          status: "success",
          processed_pages: processed_pages.to_a,
          batch_id: signal_data[:batch_id]
        }
      end
      # rubocop:enable Metrics/MethodLength

      private

      def initialize_dependencies(sync_run_id)
        @sync_run = SyncRun.find(sync_run_id)
        @sync = @sync_run.sync
        @workflow_store = ::WorkflowStoreService.new
      end

      def process_workflow_data(signal_data, page_number)
        workflow_key = "#{signal_data[:workflow_id]}:#{page_number}"
        workflow_data = @workflow_store.get_workflow_data(workflow_key)
        page_data = workflow_data[:result][:data]

        process_page_data(page_data, page_number)
      end

      def process_page_data(page_data, page_number)
        ActiveRecord::Base.transaction do
          create_sync_read_record(page_data)
          update_current_page(page_number)
          update_extraction_stats(page_data)
        end
      end

      def handle_page_error(page_number, error)
        activity.logger.error(
          "Failed to process page #{page_number}: #{error.message}",
          error: error,
          sync_run_id: @sync_run.id,
          sync_id: @sync.id
        )
        raise error
      end

      def update_extraction_stats(records)
        @sync_run.total_records_read += records.size
        @sync_run.successful_records_read += records.size
        @sync_run.save!
      end

      def create_sync_read_record(records)
        SyncReadRecord.create!(
          sync_run: @sync_run,
          sync: @sync,
          data: records
        )
      rescue ActiveRecord::RecordInvalid => e
        raise unless e.record.errors[:signature]&.include?("has already been taken")

        activity.logger.info("Skipping duplicate page for sync_id: #{@sync.id}")
      end

      def update_current_page(page_number)
        @sync_run.update!(
          current_page: page_number,
          last_extracted_at: Time.current
        )
      end

      def update_cursor(last_record)
        return if @sync.default_cursor_field.blank?

        @sync_run.update!(
          last_cursor_value: extract_cursor_value(last_record),
          last_extracted_at: Time.current
        )
      end

      def extract_cursor_value(record)
        return if @sync.default_cursor_field.blank?

        record[@sync.default_cursor_field.first]
      end

      def generate_signature(records)
        Digest::MD5.hexdigest(records.to_json)
      end
    end
  end
end
