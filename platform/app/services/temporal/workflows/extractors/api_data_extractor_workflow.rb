# frozen_string_literal: true

module Temporal
  module Workflows
    module Extractors
      class ApiDataExtractorWorkflow < ::Temporal::Workflow
        timeouts(
          execution: 43200, # 12 hours in seconds
          run: 39600,      # 11 hours in seconds
          task: 300        # 5 minutes in seconds
        )

        def execute(sync_run_id)
          initialize_workflow_state
          @sync_run_id = sync_run_id

          begin
            update_sync_status('syncing')
            
            setup_workflow
            setup_signal_handlers
            
            workflow.wait_until { pages_processed? }

            update_sync_status('synced')
            { success: true, message: 'API extraction completed' }
          rescue StandardError => e
            handle_error(e)
            { success: false, error: e.message }
          end
        end

        private

        def update_sync_status(status, error_message = nil)
          Activities::UpdateSyncStatusActivity.execute!(
            sync_run_id: @sync_run_id,
            status: status,
            error_message: error_message
          )
        end

        def handle_error(error)
          update_sync_status('error', error.message)
          workflow.logger.error("Extraction failed", {
            sync_run_id: @sync_run_id,
            error: error.message
          })
        end

        def setup_workflow
          @workflow_params = Activities::FetchWorkflowParamsActivity.execute!(@sync_run_id)
          @workflow_params[:workflow_params][:api_extractor_workflow_id] = workflow.metadata.id
          @workflow_params[:workflow_params][:api_extractor_workflow_run_id] = workflow.metadata.run_id
          start_read_workflow
          
          # Explicitly request the first page after starting the workflow
          Activities::RequestFirstPageActivity.execute!(
            workflow_id: @workflow_params[:workflow_options][:workflow_id],
            sync_run_id: @sync_run_id
          )
        end

        def setup_signal_handlers
          workflow.on_signal('page_one_completed') do |signal_data|
            handle_first_page(signal_data)
          end

          workflow.on_signal('page_processed') do |signal_data|
            handle_page_completion(signal_data)
          end
        end

        def handle_first_page(signal_data)
          return if @total_pages.present?
          return if @processed_pages.include?(1)
        
          Activities::ProcessFirstPageActivity.execute!(
            sync_run_id: @sync_run_id,
            signal_data: signal_data
          )
        
          @total_pages = signal_data[:total_pages]
          @processed_pages.add(1)
          
          # Request next page only after confirming first page is processed
          request_next_page if @total_pages > 1
        end        

        def handle_page_completion(signal_data)
          page_number = signal_data[:page_number]
          return unless should_process_page?(signal_data)
          
          Activities::ProcessPageActivity.execute!(
            sync_run_id: @sync_run_id,
            signal_data: signal_data,
            page_number: page_number
          )

          @processed_pages.add(page_number)
          request_next_page if @total_pages > page_number
        end

        def start_read_workflow
          result = Workflows::Extractors::StartConnectorDataFetchWorkflow.execute!(@workflow_params,                              
            options: { workflow_id: "start_connector_data_fetch_workflow-sync_run_id_#{@sync_run_id}" })

          if result[:success]
            Activities::RegisterWorkflowRunActivity.execute!(
              sync_run_id: @sync_run_id,
              workflow_id: result[:workflow_id],
              run_id: result[:run_id]
            ) if result[:run_id]
          else
            workflow.logger.error("Failed to start connector workflow", {
              sync_run_id: @sync_run_id,
              error: result[:error]
            })
          end
        end

        def request_next_page 
          Activities::RequestNextPageActivity.execute!(
            workflow_id: @workflow_params[:workflow_options][:workflow_id],
            sync_run_id: @sync_run_id
          )
        end

        def pages_processed?
          return false if @processed_pages.empty?
          
          expected_pages = (1..@total_pages).to_set
          @processed_pages == expected_pages
        end

        def initialize_workflow_state
          @processed_pages = Set.new
          @total_pages = nil
        end

        def should_process_page?(signal_data)
          page_number = signal_data[:page_number]
          
          return false unless @total_pages.present?
          return false if @processed_pages.include?(page_number)
          return false if page_number > @total_pages
          
          true
        end
      end
    end
  end
end
