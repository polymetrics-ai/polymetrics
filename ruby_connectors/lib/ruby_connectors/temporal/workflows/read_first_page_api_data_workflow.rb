# frozen_string_literal: true

module RubyConnectors
  module Temporal
    module Workflows
      class ReadFirstPageApiDataWorkflow < ::Temporal::Workflow
        def execute(params)
          @input = params.transform_keys(&:to_s)
          # Read first page and get total pages
          begin
            result = read_first_page

            if result[:status] == "success"
              ::Temporal.signal_workflow(
                "Temporal::Workflows::Extractors::ApiDataExtractorWorkflow",
                "first_page_completed",
                @input["api_extractor_workflow_id"],
                @input["api_extractor_workflow_run_id"],
                {
                  status: "success",
                  total_pages: result[:total_pages],
                  workflow_id: workflow.metadata.id,
                  page_number: 1,
                  id: Random.uuid
                }
              )
            else
              workflow.logger.error("First page reading failed: #{result[:error]}")
              { status: "error", error: result[:error] }
            end
          rescue StandardError => e
            workflow.logger.error("First page reading failed: #{e.message}")
            { status: "error", error: e.message }
          end
        end

        private

        def read_first_page
          new_params = @input.merge("page" => 1)
          Activities::ReadApiDataActivity.execute!(new_params)
        end
      end
    end
  end
end
