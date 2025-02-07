# frozen_string_literal: true

require "rails_helper"

RSpec.describe PipelineAction, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:pipeline) }
    it { is_expected.to belong_to(:query_action).class_name("PipelineAction").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:action_type) }
    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_presence_of(:action_data) }
    it { is_expected.to validate_numericality_of(:position).only_integer }
  end

  describe "enums" do
    it do
      expect(subject).to define_enum_for(:action_type)
        .with_values(connector_selection: 0,
                     connection_creation: 1,
                     sync_initialization: 2,
                     query_generation: 3,
                     query_execution: 4)
    end
  end

  describe "action_data validation" do
    context "when action_type is connector_selection" do
      let(:action) { build(:pipeline_action, :connector_selection) }

      it "is valid with nested connector IDs" do
        action.action_data = {
          "source" => { "connector_id" => 1 },
          "destination" => { "connector_id" => 2 }
        }
        expect(action).to be_valid
      end

      it "is invalid with missing nested keys" do
        action.action_data = { "source" => { "connector_id" => 1 } }
        expect(action).not_to be_valid
        expect(action.errors[:action_data]).to include(%r{missing required key: destination/connector_id})
      end
    end

    context "when action_type is connection_creation" do
      let(:action) { build(:pipeline_action, action_type: :connection_creation) }

      it "is valid with required keys" do
        action.action_data = {
          "streams" => ["users"],
          "created_at" => "2024-01-01T00:00:00Z",
          "connection_id" => 123
        }
        expect(action).to be_valid
      end

      it "is invalid without created_at and connection_id" do
        action.action_data = { "streams" => ["users"] }
        expect(action).not_to be_valid
        expect(action.errors[:action_data]).to include(/missing required keys: created_at, connection_id/)
      end
    end

    context "when action_type is sync_initialization" do
      let(:action) { build(:pipeline_action, action_type: :sync_initialization) }

      it "is valid with workflow run ID" do
        action.action_data = {
          "connection_id" => 123,
          "connection_workflow_run_id" => "uuid-1234"
        }
        expect(action).to be_valid
      end

      it "is invalid without workflow run ID" do
        action.action_data = { "connection_id" => 123 }
        expect(action).not_to be_valid
        expect(action.errors[:action_data]).to include(/missing required keys: connection_workflow_run_id/)
      end
    end

    context "when action_type is query_execution" do
      let(:action) { build(:pipeline_action, :query_execution) }

      it "is valid with optional explanation" do
        action.action_data["explanation"] = "Sample explanation"
        expect(action).to be_valid
      end

      it "is invalid with unexpected keys" do
        action.action_data["invalid_key"] = "bad_data"
        expect(action).not_to be_valid
        expect(action.errors[:action_data]).to include(/invalid keys: invalid_key/)
      end
    end
  end

  describe "result_data accessors" do
    let(:action) { create(:pipeline_action, :query_execution) }

    it "stores and retrieves execution status" do
      action.execution_status = "completed"
      action.save
      expect(action.reload.execution_status).to eq("completed")
    end

    it "stores and retrieves error message" do
      action.error_message = "Failed to execute"
      action.save
      expect(action.reload.error_message).to eq("Failed to execute")
    end

    it "stores and retrieves output" do
      action.output = { "rows_affected" => 10 }
      action.save
      expect(action.reload.output).to eq({ "rows_affected" => 10 })
    end
  end
end
