# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatAgent::InitializationService do
  subject { described_class.new(workspace_id: workspace.id, user_id: user.id, query: query, title: title) }

  let(:workspace) { create(:workspace) }
  let(:user) { create(:user) }
  let(:query) { "Test query" }
  let(:title) { "Test Chat" }

  before do
    allow(Temporal).to receive(:start_workflow).and_return("mock_workflow_id")
  end

  describe "#call" do
    it "creates a chat with the correct attributes" do
      result = subject.call

      chat = result[:chat]
      expect(chat.workspace_id).to eq(workspace.id)
      expect(chat.user_id).to eq(user.id)
      expect(chat.title).to eq(title)
      expect(chat.description).to eq("This chat session is dedicated to managing and executing data integration tasks through the Data Agent. It tracks ETL pipelines, connection configurations, and query executions.")
      expect(chat.status).to eq("active")
    end

    it "creates an initial message with the query" do
      result = subject.call

      chat = result[:chat]
      message = chat.messages.first
      expect(message.content).to eq(query)
      expect(message.role).to eq("user")
      expect(message.message_type).to eq("text")
    end

    it "starts a temporal workflow with the correct parameters" do
      result = subject.call

      expect(Temporal).to have_received(:start_workflow).with(
        Temporal::Workflows::Agents::DataAgent::ChatProcessingWorkflow,
        {
          chat_id: result[:chat].id,
          content: query,
          user_id: user.id,
          workspace_id: workspace.id
        },
        options: {
          workflow_id: "chat_#{result[:chat].id}",
          task_queue: "platform_queue"
        }
      )
    end

    it "returns the chat and workflow_id" do
      result = subject.call

      expect(result[:chat]).to be_a(Chat)
      expect(result[:workflow_id]).to eq("chat_#{result[:chat].id}")
    end

    context "when title is nil" do
      let(:title) { nil }

      it "uses default title" do
        result = subject.call
        expect(result[:chat].title).to eq("Data Agent Chat")
      end
    end

    context "when temporal workflow fails" do
      before do
        allow(Temporal).to receive(:start_workflow).and_raise(StandardError.new("Workflow failed"))
      end

      it "raises the error" do
        expect { subject.call }.to raise_error(StandardError, "Workflow failed")
      end
    end

    context "when creation fails" do
      before do
        allow(Chat).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "raises the error" do
        expect { subject.call }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when message creation fails" do
      before do
        allow_any_instance_of(Chat).to receive(:messages).and_return(double(create!: nil))
        allow_any_instance_of(Chat).to receive(:messages).and_raise(ActiveRecord::RecordInvalid)
      end

      it "rolls back the transaction" do
        expect { subject.call }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Chat.count).to eq(0)
      end
    end
  end
end
