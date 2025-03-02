# frozen_string_literal: true

module Temporal
  module Activities
    # rubocop:disable Metrics/ClassLength
    class LoadDataActivity < ::Temporal::Activity
      BATCH_SIZE = 10_000

      LANGUAGE_CONNECTOR_QUEUES = {
        ruby: "ruby_connectors_queue",
        python: "python_connectors_queue",
        javascript: "javascript_connectors_queue"
      }.freeze

      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      timeouts(
        start_to_close: 600,
        heartbeat: 120,
        schedule_to_close: 1800
      )

      def execute(sync_run_id, database_data_loader_workflow_id, database_data_loader_workflow_run_id)
        @sync_run = SyncRun.find(sync_run_id)
        @sync = @sync_run.sync
        @workflow_store = ::WorkflowStoreService.new
        @database_data_loader_workflow_id = database_data_loader_workflow_id
        @database_data_loader_workflow_run_id = database_data_loader_workflow_run_id

        begin
          process_write_records
          { success: true }
        rescue StandardError => e
          activity.logger.error("Failed to process write records: #{e.message}")

          { success: false, error: e.message }
        end
      end

      private

      # Efficiently process write records in predetermined batches
      def process_write_records
        # Get pending records count and calculate batches
        total_records = @sync_run.sync_write_records.where(status: :pending).count
        total_batches = (total_records.to_f / BATCH_SIZE).ceil

        # Process each batch with a clear iteration pattern
        total_batches.times do |batch_index|
          activity.heartbeat

          batch_number = batch_index + 1
          offset = batch_index * BATCH_SIZE

          # Load and process this batch
          process_batch(batch_number, offset)
        end

        # Start the write workflow with the calculated batch count
        start_write_workflow(total_batches)
      end

      # Process a single batch of records
      def process_batch(batch_number, offset)
        # Fetch a batch of records efficiently
        records_batch = fetch_records_batch(offset)
        return if records_batch.empty?

        # Prepare the batch data structure
        processed_records = {
          records: records_batch.map(&:data),
          write_record_ids: records_batch.map(&:id)
        }

        # Store batch in Redis
        store_batch_data(processed_records, batch_number)
      end

      # Fetch a batch of records from the database
      def fetch_records_batch(offset)
        @sync_run.sync_write_records
                 .where(status: :pending)
                 .select(:id, :data)
                 .limit(BATCH_SIZE)
                 .offset(offset)
                 .to_a
      end

      # Store batch data in Redis - Fixed to properly handle Redis operations
      def store_batch_data(processed_records, batch_number)
        workflow_id = "write_data_#{@sync_run.id}"
        redis_key = "#{workflow_id}:#{batch_number}"

        # Store data first
        @workflow_store.store_workflow_data(redis_key, processed_records)
      rescue Redis::CommandError => e
        activity.logger.error("Redis error while storing batch data: #{e.message}")
        raise e
      end

      def start_write_workflow(total_batches)
        workflow_id = "write_data_#{@sync_run.id}"
        workflow_params = build_database_params(workflow_id, total_batches)

        ::Temporal.start_workflow(
          determine_workflow_class,
          workflow_params,
          options: {
            workflow_id: workflow_id,
            task_queue: determine_task_queue
          }
        )
      end

      # rubocop:disable Metrics/MethodLength
      def build_database_params(workflow_id, total_batches)
        destination = @sync.connection.destination
        destination_config = destination.configuration

        {
          # Database connection params
          connector_class_name: destination.connector_class_name,
          configuration: destination_config,
          stream_name: @sync.stream_name,
          schema: @sync.destination_database_schema,
          schema_name: destination_config["schema"],
          database_name: destination_config["database"],
          primary_keys: @sync.source_defined_primary_key,

          # Workflow coordination params
          workflow_id: workflow_id,
          total_batches: total_batches,
          batch_size: BATCH_SIZE.to_i,
          database_data_loader_workflow_id: @database_data_loader_workflow_id,
          database_data_loader_workflow_run_id: @database_data_loader_workflow_run_id,
          sync_run_id: @sync_run.id
        }
      end
      # rubocop:enable Metrics/MethodLength

      def determine_workflow_class
        case @sync.connection.destination.integration_type
        when "database"
          "RubyConnectors::Temporal::Workflows::WriteDatabaseDataWorkflow"
        else
          raise "Unsupported destination type: #{@sync.connection.destination.integration_type}"
        end
      end

      def determine_task_queue
        language = @sync.connection.destination.connector_language
        LANGUAGE_CONNECTOR_QUEUES[language.to_sym] || LANGUAGE_CONNECTOR_QUEUES[:ruby]
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
