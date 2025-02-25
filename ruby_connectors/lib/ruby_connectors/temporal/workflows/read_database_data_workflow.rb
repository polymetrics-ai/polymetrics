# frozen_string_literal: true

module RubyConnectors
  module Temporal
    module Workflows
      class ReadDatabaseDataWorkflow < ::Temporal::Workflow
        DEFAULT_BATCH_SIZE = 10_000

        def execute(params)
          initialize_workflow_state(params)
          
          if @single_fetch_mode
            # Single fetch mode with provided limit
            process_batch(0, @batch_size)
          else
            # Original batch processing logic
            process_batch(0, @batch_size)
            return completion_status if @total_records.zero?

            total_batches = (@total_records.to_f / @batch_size).ceil
            (1...total_batches).each do |batch_number|
              process_batch(batch_number * @batch_size, @batch_size)
            end
          end

          completion_status
        rescue StandardError => e
          error_status(e)
        end

        private

        def initialize_workflow_state(params)
          @input = params.transform_keys(&:to_s)
          @batch_size = @input["limit"] || @input["batch_size"] || DEFAULT_BATCH_SIZE
          @single_fetch_mode = @input.key?("limit")
          @total_records = 0
          @processed_batches = Set.new
        end

        def process_batch(offset, limit)
          return if @processed_batches.include?("#{offset}-#{limit}")

          result = Activities::ReadDatabaseDataActivity.execute!(
            @input.merge("offset" => offset, "limit" => limit)
          )

          if result[:status] == "success"
            @processed_batches.add("#{offset}-#{limit}")
            @total_records = result[:total_records] if result[:total_records]&.positive?
          else
            raise "Batch processing failed at offset #{offset}: #{result[:error]}"
          end
        end

        def completion_status
          status = { 
            status: "completed", 
            total_batches: @processed_batches.size,
            total_records: @total_records
          }
          
          # Send signal to parent workflow
          if @input["parent_workflow_id"] && @input["parent_run_id"]
            ::Temporal.signal_workflow(
              @input["parent_workflow_classname"],
              "database_read_completed",
              @input["parent_workflow_id"],
              @input["parent_run_id"],
              status
            )
          end

          status
        end

        def error_status(error)
          {
            status: "error",
            error: error.message,
            processed_batches: @processed_batches.size
          }
        end
      end
    end
  end
end 