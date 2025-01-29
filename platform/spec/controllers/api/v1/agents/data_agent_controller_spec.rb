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
      let(:mock_chat) { double("Chat", id: 1) }
      let(:mock_service) { double("InitializationService", call: { chat: mock_chat, workflow_id: "test_workflow" }) }

      before do
        allow(ChatAgent::InitializationService).to receive(:new)
          .with(
            workspace_id: workspace.id,
            user_id: user.id,
            query: valid_params[:chat][:query],
            title: valid_params[:chat][:title]
          ).and_return(mock_service)
      end

      it "returns a successful response" do
        post :chat, params: valid_params
        expect(response).to have_http_status(:ok)
      end

      it "returns the chat ID and workflow ID" do
        post :chat, params: valid_params
        expect(response.parsed_body).to include(
          "data" => hash_including(
            "chat_id" => mock_chat.id,
            "workflow_id" => "test_workflow"
          )
        )
      end

      it "calls the initialization service" do
        expect(mock_service).to receive(:call)
        post :chat, params: valid_params
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
end
