# frozen_string_literal: true

module Etl
  class Error < StandardError; end
  class UnsupportedIntegrationType < Error; end
  class WorkflowExecutionError < Error; end
end
