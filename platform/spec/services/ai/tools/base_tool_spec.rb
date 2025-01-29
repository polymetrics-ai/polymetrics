# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ai::Tools::BaseTool do
  let(:workspace_id) { 123 }
  let(:base_tool) { described_class.new(workspace_id: workspace_id) }

  describe "#initialize" do
    it "sets workspace_id" do
      expect(base_tool.workspace_id).to eq(workspace_id)
    end
  end

  describe "error handling" do
    describe "#handle_error" do
      it "returns error structure" do
        error = StandardError.new("test error")
        result = base_tool.send(:handle_error, error)
        expect(result).to eq({
                               status: :error,
                               error: "test error"
                             })
      end
    end

    describe "#handle_success" do
      it "returns success structure" do
        data = { key: "value" }
        result = base_tool.send(:handle_success, data)
        expect(result).to eq({
                               status: :success,
                               data: data
                             })
      end
    end

    describe "#handle_validation_error" do
      it "returns validation error structure" do
        error = StandardError.new("validation error")
        result = base_tool.send(:handle_validation_error, error)
        expect(result).to eq({
                               status: :validation_error,
                               error: "validation error"
                             })
      end
    end
  end

  describe "ValidationError" do
    it "inherits from StandardError" do
      expect(described_class::ValidationError).to be < StandardError
    end
  end

  describe "Langchain integration" do
    it "extends Langchain::ToolDefinition" do
      expect(described_class.singleton_class.included_modules).to include(Langchain::ToolDefinition)
    end
  end
end
