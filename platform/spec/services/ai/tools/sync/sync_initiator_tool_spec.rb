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
  end

  describe "#initiate_sync" do
    context "when sync is successful" do
      it "initiates sync and creates pipeline action" do
        result = subject.initiate_sync(connection_id: connection.id)

        expect(result[:success]).to be true
        action = PipelineAction.last
        expect(action.action_type).to eq("sync_initialization")
        expect(action.action_data["connection_id"]).to eq(connection.id)
        expect(action.action_data["connection_workflow_run_id"]).to eq(workflow_run_id)
      end
    end

    context "when connection is already running" do
      before do
        allow(Connection).to receive(:find).and_return(connection)
        allow(connection).to receive(:running?).and_return(true)
      end

      it "returns without initiating sync" do
        expect(Connections::StartDataSyncService).not_to receive(:new)
        subject.initiate_sync(connection_id: connection.id)
      end
    end

    context "when error occurs" do
      before do
        allow(Connections::StartDataSyncService).to receive(:new).and_raise(StandardError.new("Sync failed"))
      end

      it "handles the error gracefully" do
        result = subject.initiate_sync(connection_id: connection.id)

        expect(result[:status]).to eq(:error)
        expect(result[:error]).to include("Sync failed")
      end
    end
  end

  describe "private methods" do
    describe "#create_sync_pipeline_action" do
      it "creates a sync initialization action" do
        create(:message, chat: chat, pipeline: pipeline, message_type: "pipeline")

        action = subject.send(:create_sync_pipeline_action, connection, workflow_run_id)

        expect(action).to be_persisted
        expect(action.pipeline).to eq(pipeline)
        expect(action.position).to eq(1)
      end
    end

    describe "#build_success_response" do
      it "returns formatted success response" do
        response = subject.send(:build_success_response, connection, workflow_run_id)

        expect(response).to eq({
                                 success: true,
                                 message: "Sync initiated for connection #{connection.id}",
                                 connection_workflow_run_id: workflow_run_id
                               })
      end
    end
  end
end
