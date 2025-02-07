# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ai::Assistants::EtlAssistant, :vcr do
  let(:workspace) { create(:workspace) }
  let(:chat) { create(:chat, workspace: workspace) }
  let(:query) { "Create a connection between source A and destination B" }
  let(:assistant) { described_class.new(workspace_id: workspace.id, chat_id: chat.id, query: query) }

  describe "#process_message" do
    it "processes the message and returns a response" do
      VCR.use_cassette("etl_assistant/process_message", record: :once, allow_playback_repeats: true) do
        result = assistant.process_message

        expect(result).to be_a(Hash)
        expect(result).to have_key(:content)
        expect(result[:content]).to be_present
        expect(result).to have_key(:tool_calls)
        expect(chat.reload.tool_call_data).to be_present
      end
    end

    it "handles API errors gracefully" do
      VCR.use_cassette("etl_assistant/api_error", record: :once) do
        allow_any_instance_of(Langchain::LLM::OpenAI).to receive(:chat).and_raise(StandardError.new("API Error"))

        expect { assistant.process_message }.to raise_error(StandardError)
      end
    end
  end

  describe "#build_tools" do
    it "returns an array of tools" do
      tools = assistant.send(:build_tools)

      expect(tools).to be_an(Array)
      expect(tools.size).to eq(4)
      expect(tools[0]).to be_a(Ai::Tools::Connector::ConnectorSelectionTool)
      expect(tools[1]).to be_a(Ai::Tools::Connection::ConnectionCreationTool)
      expect(tools[2]).to be_a(Ai::Tools::Sync::SyncInitiatorTool)
      expect(tools[3]).to be_a(Ai::Tools::Query::QueryGenerationTool)
    end
  end

  describe "#build_instructions" do
    it "returns formatted instructions string" do
      instructions = assistant.send(:build_instructions)
      expect(instructions).to be_a(String)
      expect(instructions).to include("JSON Schema")
    end
  end

  describe "#default_llm" do
    it "returns an OpenAI LLM instance" do
      llm = assistant.send(:default_llm)
      expect(llm).to be_a(Langchain::LLM::OpenAI)
      expect(llm.instance_variable_get(:@defaults)[:chat_model]).to eq("gpt-4o")
    end
  end

  describe "#format_response" do
    let(:response) { "Sample response" }
    let(:tool_calls) { [{ id: 1, tool: "test", method: "test", arguments: {} }] }

    before do
      assistant.instance_variable_set(:@tool_calls, tool_calls)
      assistant.instance_variable_set(:@assistant, double(messages: [double(content: response)]))
    end

    it "formats the response correctly" do
      VCR.use_cassette("etl_assistant/format_response") do
        result = assistant.send(:format_response, response)
        expect(result[:content]).to be_present
      end
    end
  end
end
