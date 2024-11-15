module RubyConnectors
  module Temporal
    module Workflows
      class ReadApiDataWorkflow < ::Temporal::Workflow
        def execute(params)
          Activities::ReadApiDataActivity.execute!(params)
        end
      end
    end
  end
end 