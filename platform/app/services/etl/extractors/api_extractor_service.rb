# frozen_string_literal: true

module Etl
  module Extractors
    class ApiExtractorService
      class ExtractionError < StandardError; end

      def initialize(sync_run)
        @sync_run = sync_run
        @sync = sync_run.sync
        @cursor_field = @sync.default_cursor_field&.first
        @current_page = @sync_run.current_page || 1
      end

      def call
        return unless validate_and_initialize_extraction

        extract_data
      end

      private

      # Extraction Flow Control
      def validate_and_initialize_extraction
        if @sync_run.total_pages
          @current_page = [@current_page, @sync_run.current_page + 1].max
          return true
        end

        result = extract_first_page
        return false unless result

        initialize_pagination(result)
      end

      def extract_data
        extract_remaining_pages while more_pages_to_process?
      end

      def extract_first_page
        result = fetch_page_data(@current_page)
        return if result.nil? || result[:data].empty?

        save_page_data(result)
        result
      rescue ActiveRecord::RecordInvalid => e
        handle_duplicate_page(e, @current_page) ? result : nil
      end

      def extract_remaining_pages
        result = extract_single_page(@current_page)
        @current_page += 1 if result
      end

      # Page Processing
      def extract_single_page(page)
        result = fetch_page_data(page)
        return false if result.nil? || result[:data].empty?

        save_page_data(result)
        update_current_page(page)
      rescue ExtractionError => e
        log_extraction_error(page, e)
        false
      end

      def save_page_data(result)
        validate_result_format(result)
        created = create_sync_read_record(result[:data])
        update_extraction_stats(result) if created
      end

      # Data Fetching
      def fetch_page_data(page)
        result = execute_workflow(page)
        return result.payload if result.success?

        raise ExtractionError, result.error.message
      rescue StandardError => e
        raise ExtractionError, e.message
      end

      def execute_workflow(page)
        Extractors::WorkflowExecutionService.new(
          sync: @sync,
          options: {
            page: page,
            workflow_id: generate_workflow_id(page)
          }
        ).execute
      end

      # State Management
      def more_pages_to_process?
        !@sync_run.extraction_completed &&
          @current_page <= (@sync_run.total_pages || Float::INFINITY)
      end

      # Record Management
      def create_sync_read_record(records)
        SyncReadRecord.create!(
          sync_run: @sync_run,
          sync: @sync,
          data: records
        )
      rescue ActiveRecord::RecordInvalid => e
        raise unless e.message.include?("Signature has already been taken")

          Rails.logger.info("Skipping duplicate page for sync_id: #{@sync.id}")
          false # Record was skipped

            # Re-raise other validation errors
      end

      def update_extraction_stats(result)
        update_sync_run_stats(result[:data].size)
        update_sync_run_cursor(result[:data].last)
      end

      # Helper Methods
      def generate_workflow_id(page)
        "read_data_#{@sync.id}_page_#{page}_#{SecureRandom.uuid}"
      end

      def validate_result_format(result)
        raise ExtractionError, "Invalid result format" unless result && result[:data].present?
      end

      def handle_duplicate_page(error, page)
        return false unless error.message.include?("Signature has already been taken")

        Rails.logger.info("Skipping duplicate page for sync_id: #{@sync.id}, page: #{page}")
        update_current_page(page)
      end

      # Database Updates
      def initialize_pagination(result)
        @sync_run.update!(
          total_pages: result[:total_pages],
          last_extracted_at: Time.current,
          last_cursor_value: extract_cursor_value(result[:data].last)
        )
        @current_page += 1
      end

      def update_current_page(page)
        @sync_run.update!(current_page: page)
      end

      def update_sync_run_stats(records_count)
        @sync_run.increment!(:total_records_read, records_count)
        @sync_run.increment!(:successful_records_read, records_count)
      end

      def update_sync_run_cursor(last_record)
        @sync_run.update!(
          last_cursor_value: extract_cursor_value(last_record),
          last_extracted_at: Time.current
        )
      end

      def extract_cursor_value(record)
        return nil unless @cursor_field && record

        record[@cursor_field.to_sym]
      end

      def log_extraction_error(page, error)
        @sync_run.sync_logs.create!(
          log_type: :error,
          message: "Failed to extract data for page #{page}: #{error.message}",
          emitted_at: Time.current
        )
      end
    end
  end
end
