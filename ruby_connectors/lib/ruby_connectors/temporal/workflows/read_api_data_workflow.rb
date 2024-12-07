# frozen_string_literal: true

module RubyConnectors
  module Temporal
    module Workflows
      class ReadApiDataWorkflow < ::Temporal::Workflow
        def execute(params)
          initialize_workflow_state(params)
          setup_signal_handlers
          
          workflow.wait_until { extraction_complete? }

          signal_batch_completion(@completed_pages)
          { status: "completed", pages: @completed_pages }
        end

        private

        def initialize_workflow_state(params)
          @input = params.transform_keys(&:to_s)
          @total_pages = @input["total_pages"]
          @completed_pages = Set.new
          @signaled_pages = Set.new
          @paged_to_be_completed = Set.new((2..@total_pages).to_a)
        end

        def setup_signal_handlers
          workflow.on_signal("fetch_page_batch") do |signal_data|
            workflow.logger.info("Received fetch_page_batch signal: #{signal_data}")
            process_page_batch(signal_data[:pages])
          end
        end

        def process_page_batch(pages)
          workflow.logger.info("Processing page batch: #{pages}")
          
          pages.each do |page_number|
            next if @completed_pages.include?(page_number)
            
            new_params = @input.merge("page" => page_number)
            result = Activities::ReadApiDataActivity.execute!(new_params)
            
            if result[:status] == "success"
              @completed_pages.add(result[:page_number])
            else
              workflow.logger.error("Failed to process page #{page_number}: #{result[:error]}")
            end
          end
        end

        def signal_batch_completion(pages)
          workflow.logger.info("Signaling read api data workflow completion for workflow: #{@input["workflow_id"]}")
          
          ::Temporal.signal_workflow(
            "Temporal::Workflows::Extractors::ApiDataExtractorWorkflow",
            "page_batch_completed",
            @input["api_extractor_workflow_id"],
            @input["api_extractor_workflow_run_id"],
            {
              workflow_id: @input["workflow_id"],
              pages: pages,
              batch_id: Digest::SHA256.hexdigest(pages.to_s)
            }
          )
        end

        def extraction_complete?
          workflow.logger.info("Completed pages: #{@completed_pages}")
          workflow.logger.info("Paged to be completed: #{@paged_to_be_completed}")

          @completed_pages == @paged_to_be_completed
        end
      end
    end
  end
end
