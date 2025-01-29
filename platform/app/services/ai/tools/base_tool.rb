# frozen_string_literal: true

module Ai
  module Tools
    class BaseTool
      extend Langchain::ToolDefinition

      attr_reader :workspace_id

      def initialize(workspace_id:)
        @workspace_id = workspace_id
      end

      private

      def handle_error(error)
        {
          status: :error,
          error: error&.to_s || "Unknown error"
        }
      end

      def handle_success(data)
        {
          status: :success,
          data: data
        }
      end

      def handle_validation_error(error)
        {
          status: :validation_error,
          error: error.message
        }
      end

      class ValidationError < StandardError; end
    end
  end
end
