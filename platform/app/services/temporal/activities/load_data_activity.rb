module Temporal
  module Activities
    class LoadDataActivity < ::Temporal::Activity
      BATCH_SIZE = 10000

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
          { success: false, error: e.message }
        end
      end

      private

      def process_write_records
        record_ids = @sync_run.sync_write_records.where(status: :pending).pluck(:id)
        total_batches = (record_ids.size.to_f / BATCH_SIZE).ceil
        
        processed_records = { records: [], write_record_ids: [] }
        
        record_ids.each_slice(BATCH_SIZE).with_index(1) do |batch_ids, batch_number|
          activity.heartbeat
          process_batch(batch_ids, processed_records)
          
          # Store batch data in Redis when we reach BATCH_SIZE or it's the last batch
          if processed_records[:records].size >= BATCH_SIZE || batch_number == total_batches
            store_batch_data(processed_records, batch_number)
            processed_records = { records: [], write_record_ids: [] }
          end
        end

        start_write_workflow(total_batches)
      end

      def process_batch(batch_ids, processed_records)
        Parallel.each(batch_ids, in_threads: 10) do |record_id|
          ActiveRecord::Base.connection_pool.with_connection do
            begin
              record = @sync_run.sync_write_records.find(record_id)
              processed_records[:records] << record.data
              processed_records[:write_record_ids] << record.id
              activity.heartbeat
            rescue StandardError => e
              handle_record_error(record_id, e)
            ensure
              ActiveRecord::Base.connection_pool.release_connection
            end
          end
        end
      end

      def store_batch_data(processed_records, batch_number)
        workflow_id = "write_data_#{@sync_run.id}"
        redis_key = "#{workflow_id}:#{batch_number}"
        @workflow_store.store_workflow_data(redis_key, processed_records)
      end

      def handle_record_error(record_id, error)
        activity.logger.error(
          "Failed to process record #{record_id}: #{error.message}",
          error: error,
          sync_run_id: @sync_run.id,
          sync_id: @sync.id
        )
        raise error
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
          batch_size: BATCH_SIZE,
          database_data_loader_workflow_id: @database_data_loader_workflow_id,
          database_data_loader_workflow_run_id: @database_data_loader_workflow_run_id,
          sync_run_id: @sync_run.id
        }
      end

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
  end
end
