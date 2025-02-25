# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ai::Tools::Sync::SyncInitiatorTool do
  subject { described_class.new(workspace_id: workspace.id, chat_id: chat.id) }

  let(:workspace) { create(:workspace) }
  let(:chat) { create(:chat, workspace: workspace) }
  let(:message) { create(:message, chat: chat, message_type: "pipeline") }
  let(:pipeline) { create(:pipeline, message: message) }
  let(:connection) { create(:connection, workspace: workspace) }
  let(:workflow_run_id) { SecureRandom.uuid }

  before do
    allow(Connections::StartDataSyncService).to receive(:new).and_return(
      double(call: workflow_run_id)
    )
    create(:message,
           chat: chat,
           message_type: "pipeline",
           pipeline: pipeline)
    chat.connections << connection
  end

  describe "#initiate_sync" do
    context "when sync is successful" do
      it "initiates sync and creates pipeline action" do
        result = subject.initiate_sync

        expect(result[:success]).to be true
        action = PipelineAction.last
        expect(action.action_type).to eq("sync_initialization")
        expect(action.action_data["connections"].first["connection_id"]).to eq(connection.id)
        expect(action.action_data["connections"].first["connection_workflow_run_id"]).to eq(workflow_run_id)
      end
    end

    context "when connection is already running" do
      before do
        allow_any_instance_of(Connection).to receive(:running?).and_return(true)
        allow(Connections::StartDataSyncService).to receive(:new).and_call_original
      end

      it "returns without initiating sync" do
        expect(Connections::StartDataSyncService).not_to receive(:new)
        subject.initiate_sync
      end
    end

    context "when error occurs" do
      before do
        allow(Connections::StartDataSyncService).to receive(:new).and_raise(StandardError.new("Sync failed"))
      end

      it "handles the error gracefully" do
        result = subject.initiate_sync
        failed_result = result[:results].find { |r| r[:status] == :failed }

        expect(failed_result[:error]).to include("Sync failed")
      end
    end
  end

  describe "private methods" do
    describe "#create_sync_pipeline_action" do
      it "creates a sync initialization action" do
        sync_results = [{
          connection_id: connection.id,
          connection_workflow_run_id: workflow_run_id,
          status: :success
        }]

        subject.send(:create_sync_pipeline_action, sync_results)
        action = PipelineAction.last

        expect(action).to be_persisted
        expect(action.pipeline).to eq(pipeline)
        expect(action.position).to eq(1)
      end
    end

    describe "#build_success_response" do
      it "returns formatted success response" do
        sync_results = [{
          connection_id: connection.id,
          connection_workflow_run_id: workflow_run_id,
          status: :success
        }]

        response = subject.send(:build_success_response, sync_results)

        expect(response).to include(
          success: true,
          message: "Sync initiated for 1 connections",
          results: sync_results
        )
      end
    end
  end
end
