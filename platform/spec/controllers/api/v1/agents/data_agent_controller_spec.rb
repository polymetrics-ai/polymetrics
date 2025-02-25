# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Agents::DataAgentController, type: :controller do
  let(:user) { create(:user) }
  let(:valid_params) { { chat: { query: "Sample query", title: "Test Chat" } } }
  let(:workspace) { user.workspaces.first }

  before do
    sign_in_and_set_token(user)
  end

  describe "POST #chat" do
    context "with valid parameters" do
      before do
        # Mock Temporal to return the generated workflow ID from options
        allow(Temporal).to receive(:start_workflow) do |_, _, options|
          options[:options][:workflow_id]
        end
      end

      it "returns a successful response" do
        post :chat, params: valid_params
        expect(response).to have_http_status(:ok)
      end

      it "creates a new chat with message" do
        expect do
          post :chat, params: valid_params
        end.to change(Chat, :count).by(1)

        chat = Chat.last
        expect(chat.messages.count).to eq(1)
        expect(chat.messages.first.content).to eq("Sample query")
      end

      it "returns the chat ID and workflow ID" do
        post :chat, params: valid_params
        chat = Chat.last
        message = chat.messages.first

        expect(response.parsed_body).to eq(
          "data" => {
            "id" => chat.id,
            "title" => "Test Chat",
            "status" => "active",
            "created_at" => chat.created_at.utc.to_s,
            "workflow_id" => "chat_#{chat.id}",
            "description" => "This chat session is dedicated to managing and executing data " \
                             "integration tasks through the Data Agent. It tracks ETL pipelines, " \
                             "connection configurations, and query executions.",
            "icon_url" => "/icon-data-agent.svg",
            "message_count" => 1,
            "last_message" => {
              "content" => "Sample query",
              "role" => "user",
              "message_type" => "text",
              "created_at" => message.created_at.utc.to_s
            }
          }
        )
      end

      it "starts temporal workflow with correct parameters" do
        post :chat, params: valid_params
        chat = Chat.last

        expect(Temporal).to have_received(:start_workflow).with(
          Temporal::Workflows::Agents::DataAgent::ChatProcessingWorkflow,
          hash_including(
            chat_id: chat.id,
            content: "Sample query",
            workspace_id: workspace.id
          ),
          options: hash_including(
            workflow_id: "chat_#{chat.id}",
            task_queue: "platform_queue"
          )
        )
      end
    end

    context "with invalid parameters" do
      it "returns an error for missing chat params" do
        post :chat, params: {}
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns an error for missing query" do
        post :chat, params: { chat: { title: "Test" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when service raises an error" do
      before do
        allow_any_instance_of(ChatAgent::InitializationService).to receive(:call)
          .and_raise(StandardError.new("Test error"))
      end

      it "returns an error response" do
        post :chat, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to include(
          "error" => "Test error"
        )
      end
    end
  end

  describe "GET #history" do
    let!(:user_chats) do
      create_list(:chat, 2,
                  user: user,
                  workspace: workspace,
                  created_at: 1.day.ago).each do |chat|
        create_list(:message, 3, chat: chat)
      end
    end
    let!(:new_chat) do
      create(:chat, user: user, workspace: workspace, created_at: Time.current).tap do |c|
        create_list(:message, 3, chat: c)
      end
    end
    let(:other_user_chat) { create(:chat, user: create(:user), workspace: workspace) }
    let(:other_workspace_chat) { create(:chat, user: user, workspace: create(:workspace)) }

    before { get :history }

    it "returns a successful response" do
      expect(response).to have_http_status(:ok)
    end

    it "returns only current user's chats in current workspace" do
      data = response.parsed_body["data"]
      expect(data.size).to eq(3) # 2 created + 1 new_chat
      expect(data.pluck("id"))
        .to contain_exactly(*user_chats.map(&:id), new_chat.id)
    end

    it "orders chats by created_at descending" do
      expect(response.parsed_body["data"].first["id"]).to eq(new_chat.id)
    end

    it "includes correct history view fields" do
      chat_data = response.parsed_body["data"].first
      expect(chat_data).to include(
        "id",
        "title",
        "status",
        "created_at",
        "description",
        "message_count",
        "last_message"
      )
    end

    it "includes message count from eager-loaded messages" do
      expect(response.parsed_body["data"].first["message_count"]).to eq(3)
      expect(response.parsed_body["data"].last["message_count"]).to eq(3)
    end

    it "includes formatted last message" do
      last_message = response.parsed_body["data"].first["last_message"]
      expect(last_message).to include(
        "content",
        "role",
        "message_type",
        "created_at"
      )
    end

    context "when no chats exist" do
      before do
        Chat.destroy_all
        get :history
      end

      it "returns empty array" do
        expect(response.parsed_body["data"]).to be_empty
      end
    end
  end
end
