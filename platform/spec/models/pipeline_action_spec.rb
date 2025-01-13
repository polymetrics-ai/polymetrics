# frozen_string_literal: true

require "rails_helper"

RSpec.describe PipelineAction, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:pipeline) }
    it { is_expected.to belong_to(:query_action).class_name("PipelineAction").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:action_type) }
    it { is_expected.to validate_presence_of(:order) }
    it { is_expected.to validate_presence_of(:action_data) }
    it { is_expected.to validate_numericality_of(:order).only_integer }
  end

  describe "enums" do
    it do
      expect(subject).to define_enum_for(:action_type)
        .with_values(connection_creation: 0, query_execution: 1, summary_generation: 2)
    end
  end

  describe "action_data validation" do
    context "when action_type is connection_creation" do
      let(:action) { build(:pipeline_action, :connection_creation) }

      it "is valid with required keys" do
        action.action_data = {
          "source_connector_id" => 1,
          "streams" => %w[users orders]
        }
        expect(action).to be_valid
      end

      it "is invalid without required keys" do
        action.action_data = { "source_connector_id" => 1 }
        expect(action).not_to be_valid
        expect(action.errors[:action_data]).to include(/missing required keys: streams/)
      end
    end

    context "when action_type is query_execution" do
      let(:action) { build(:pipeline_action, :query_execution) }

      it "is valid with required keys" do
        action.action_data = {
          "query" => "SELECT * FROM users",
          "connection_id" => 1
        }
        expect(action).to be_valid
      end

      it "is invalid without required keys" do
        action.action_data = { "query" => "SELECT * FROM users" }
        expect(action).not_to be_valid
        expect(action.errors[:action_data]).to include(/missing required keys: connection_id/)
      end
    end

    context "when action_type is summary_generation" do
      let(:action) { build(:pipeline_action, :summary_generation) }

      it "is valid with required keys and query_action" do
        query_action = create(:pipeline_action, :query_execution)
        action.query_action = query_action
        action.action_data = { "summary_description" => "Summarize user data" }
        expect(action).to be_valid
      end

      it "is invalid without query_action" do
        action.action_data = { "summary_description" => "Summarize user data" }
        expect(action).not_to be_valid
        expect(action.errors[:query_action_id])
          .to include("must be present for summary generation actions")
      end

      it "is invalid without required keys" do
        action.action_data = {}
        expect(action).not_to be_valid
        expect(action.errors[:action_data])
          .to include(/missing required keys: summary_description/)
      end
    end
  end

  describe "result_data accessors" do
    let(:action) { create(:pipeline_action) }

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
