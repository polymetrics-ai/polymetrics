module RubyConnectors
  module Temporal
    module Workflows
      class ReadApiDataWorkflow < ::Temporal::Workflow
        timeouts execution: 24.hours, run: 23.hours, task: 5.minutes

        def execute(params)
          @input = params.transform_keys(&:to_s)
          @completed_pages = Set.new
          @signaled_pages = Set.new
          @total_pages = nil

          process_page(@input) if @input["page"] == 1
          
          # Setup signal handler for fetch_page
          workflow.on_signal('fetch_page') do |input|
            workflow.logger.info("received signal for page: #{input}")
            page_number = input[:page_number]
            new_params = @input.merge("page" => page_number)
            process_page(new_params)
          end

          # Wait until all pages are processed
          workflow.wait_until { extraction_complete? }
          
          { status: 'completed', total_pages: @total_pages }
        end

        private

        def process_page(params)
          result = Activities::ReadApiDataActivity.execute!(params)
          
          if result[:status] == 'success'
            total_pages = result[:total_pages]
            page_number = params["page"]
            
            @completed_pages.add(page_number)
            
            if page_number == 1 && !@signaled_pages.include?(page_number)
              @total_pages = total_pages
              signal_first_page_completion(params, total_pages)
            elsif !@signaled_pages.include?(page_number)
              signal_page_completion(params, page_number)
            end

            @signaled_pages.add(page_number)
          end
          
          result
        end

        def signal_first_page_completion(params, total_pages)
          workflow.logger.info("sending signal for processing page: 1")
          ::Temporal.signal_workflow(
            "Temporal::Workflows::Extractors::ApiDataExtractorWorkflow",
            "page_one_completed",
            params["api_extractor_workflow_id"],
            params["api_extractor_workflow_run_id"],
            { 
              workflow_id: params["workflow_id"],
              page_number: 1,
              total_pages: total_pages
            }
          )
        end

        def signal_page_completion(params, page_number)
          workflow.logger.info("sending signal for processing page: #{page_number}")
          ::Temporal.signal_workflow(
            "Temporal::Workflows::Extractors::ApiDataExtractorWorkflow",
            "page_processed",
            params["api_extractor_workflow_id"],
            params["api_extractor_workflow_run_id"],
            { 
              workflow_id: params["workflow_id"],
              page_number: page_number
            }
          )
        end

        def extraction_complete?
          return false unless @total_pages

          expected_pages = (1..@total_pages).to_set
          @completed_pages == expected_pages
        end
      end
    end
  end
end