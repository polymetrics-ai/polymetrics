# frozen_string_literal: true

module Etl
  class Errors < StandardError; end
  class UnsupportedIntegrationType < Errors; end
  class WorkflowExecutionError < Errors; end
end
