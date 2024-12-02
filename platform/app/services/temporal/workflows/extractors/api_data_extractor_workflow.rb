# frozen_string_literal: true

module Temporal
  module Workflows
    module Extractors
      # rubocop:disable Metrics/ClassLength
      class ApiDataExtractorWorkflow < ::Temporal::Workflow
        def execute(sync_run_id)
          initialize_state(sync_run_id)
          perform_extraction
        rescue StandardError => e
          handle_error(e)
          { success: false, error: e.message }
        end

        private

        def initialize_state(sync_run_id)
          @processed_pages = Set.new
          @total_pages = nil
          @sync_run_id = sync_run_id
          @processed_signals = Set.new
        end

        def perform_extraction
          update_sync_status("syncing")
          fetch_and_setup_workflow
          process_first_page
          handle_remaining_pages if @total_pages&.> 1 # @total_pages && @total_pages > 1
          finalize_extraction
        end

        def fetch_and_setup_workflow
          @workflow_params = Activities::FetchWorkflowParamsActivity.execute!(@sync_run_id)
          @workflow_params[:workflow_params].merge!(
            api_extractor_workflow_id: workflow.metadata.id,
            api_extractor_workflow_run_id: workflow.metadata.run_id
          )
        end

        def process_first_page
          first_page_result = start_first_page_workflow
          register_workflow_run(first_page_result) if first_page_result[:success]

          workflow.on_signal("first_page_completed") do |signal_data|
            signal_id = "first_page_#{signal_data[:id]}" # Add unique identifier
            unless @processed_signals.include?(signal_id)
              @processed_signals.add(signal_id)
              handle_first_page_completion(signal_data)
            end
          end

          workflow.wait_until { @processed_pages.include?(1) }
        end

        def handle_first_page_completion(signal_data)
          return unless signal_data[:status] == "success"

          Activities::ProcessFirstPageActivity.execute!(
            sync_run_id: @sync_run_id,
            signal_data: signal_data
          )
          @total_pages = signal_data[:total_pages]
          @processed_pages.add(1)
        end

        def handle_remaining_pages
          @workflow_params[:workflow_params][:total_pages] = @total_pages
          start_remaining_pages_workflow
          request_page_batches
          setup_batch_completion_handler
          wait_for_all_pages
        end

        def start_remaining_pages_workflow
          result = Workflows::Extractors::StartConnectorDataFetchWorkflow.execute!(
            @workflow_params,
            options: { workflow_id: remaining_pages_workflow_id }
          )
          register_workflow_run(result) if result[:success]
        end

        def request_page_batches
          remaining_pages = (2..@total_pages).to_a
          remaining_pages.each_slice(100) do |batch|
            Activities::RequestPageBatchActivity.execute!(
              workflow_id: @workflow_params[:workflow_options][:workflow_id],
              sync_run_id: @sync_run_id,
              pages: batch
            )
          end
        end

        def setup_batch_completion_handler
          workflow.on_signal("page_batch_completed") do |signal_data|
            signal_id = "batch_#{signal_data[:batch_id]}" # Add unique identifier
            unless @processed_signals.include?(signal_id)
              @processed_signals.add(signal_id)
              process_completed_batch(signal_data)
            end
          end
        end

        def process_completed_batch(signal_data)
          signal_data[:pages].each do |page_number|
            next if @processed_pages.include?(page_number)
            next unless should_process_page?(page_number)

            process_single_page(signal_data, page_number)
          end
        end

        def process_single_page(signal_data, page_number)
          Activities::ProcessPageActivity.execute!(
            sync_run_id: @sync_run_id,
            signal_data: signal_data,
            page_number: page_number
          )
          @processed_pages.add(page_number)
        end

        def wait_for_all_pages
          workflow.wait_until { pages_processed? }
        end

        def finalize_extraction
          update_sync_status("synced")
          { success: true, message: "API extraction completed" }
        end

        def start_first_page_workflow
          Workflows::Extractors::StartFirstPageWorkflow.execute!(
            { sync_run_id: @sync_run_id, workflow_params: @workflow_params },
            options: { workflow_id: first_page_workflow_id }
          )
        end

        def should_process_page?(page_number)
          return false if @total_pages.blank?
          return false if @processed_pages.include?(page_number)
          return false if page_number > @total_pages

          true
        end

        def pages_processed?
          return false if @processed_pages.empty?

          expected_pages = (1..@total_pages).to_set
          @processed_pages == expected_pages
        end

        def register_workflow_run(result)
          Activities::RegisterWorkflowRunActivity.execute!(
            sync_run_id: @sync_run_id,
            workflow_id: result[:workflow_id],
            run_id: result[:run_id]
          )
        end

        def update_sync_status(status, error_message = nil)
          Activities::UpdateSyncStatusActivity.execute!(
            sync_run_id: @sync_run_id,
            status: status,
            error_message: error_message
          )
        end

        def handle_error(error)
          update_sync_status("error", error.message)
          workflow.logger.error(
            "Extraction failed",
            {
              sync_run_id: @sync_run_id,
              error: error.message
            }
          )
        end

        def first_page_workflow_id
          "start_first_page_connector_data_fetch_workflow-sync_run_id_#{@sync_run_id}"
        end

        def remaining_pages_workflow_id
          "start_connector_data_fetch_workflow-sync_run_id_#{@sync_run_id}"
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
