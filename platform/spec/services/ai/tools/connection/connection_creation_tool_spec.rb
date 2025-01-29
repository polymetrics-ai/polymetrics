# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ai::Tools::Connection::ConnectionCreationTool do
  subject { described_class.new(workspace_id: workspace.id, chat_id: chat.id) }

  let(:workspace) { create(:workspace) }
  let(:chat) { create(:chat, workspace: workspace) }
  let(:connector) { create(:connector, workspace: workspace) }
  let(:pipeline_message) { create(:message, chat: chat, message_type: "pipeline", content: pipeline_content.to_json) }
  let(:pipeline_content) do
    {
      source: {
        connector_id: connector.id,
        streams: [
          { name: "stream1" },
          { name: "stream2" }
        ]
      }
    }
  end

  let(:mock_schema) do
    {
      "stream1" => {
        "name" => "stream1",
        "properties" => {
          "id" => { "type" => "integer" },
          "name" => { "type" => "string" },
          "email" => { "type" => "string" },
          "created_at" => { "type" => "string", "format" => "date-time" }
        },
        "x-supported_sync_modes" => %w[full_refresh incremental],
        "x-default_sync_mode" => "incremental",
        "x-source_defined_cursor" => true,
        "x-default_cursor_field" => ["updated_at"],
        "x-source_defined_primary_key" => ["id"]
      },
      "stream2" => {
        "name" => "stream2",
        "properties" => {
          "id" => { "type" => "integer" },
          "name" => { "type" => "string" }
        },
        "x-supported_sync_modes" => ["full_refresh"],
        "x-default_sync_mode" => "full_refresh"
      },
      "stream3" => {
        "name" => "stream3",
        "properties" => {
          "id" => { "type" => "integer" },
          "name" => { "type" => "string" }
        },
        "x-supported_sync_modes" => ["incremental"],
        "x-default_sync_mode" => "incremental",
        "x-source_defined_cursor" => true,
        "x-default_cursor_field" => ["updated_at"]
      }
    }
  end

  before do
    # Mock Temporal calls for schema fetching
    allow(Temporal).to receive_messages(
      start_workflow: "mock_workflow_id",
      await_workflow_result: mock_schema
    )

    # Mock the schema service to return our mock schema
    allow_any_instance_of(Catalogs::FetchSchemaService).to receive(:call).and_return(mock_schema)

    pipeline_message
  end

  describe "#create_connection" do
    it "creates a connection with the specified streams" do
      result = subject.create_connection(query: "test query")

      expect(result[:success]).to be true
      expect(result[:connection_id]).to be_present
      expect(result[:message]).to include("Successfully created connection with 2 streams: stream1, stream2")
    end

    context "when connection already exists" do
      let(:existing_connection) do
        create(:connection, workspace: workspace,
                            name: "#{connector.name}_#{Digest::SHA256.hexdigest(%w[stream1 stream2].join("-"))[0..15]} Connection")
      end

      before do
        existing_connection
      end

      it "uses the existing connection" do
        result = subject.create_connection(query: "test query")

        expect(result[:success]).to be true
        expect(result[:message]).to include("Using existing connection")
        expect(result[:connection_id]).to eq(existing_connection.id)
      end
    end

    context "when error occurs during connection creation" do
      before do
        allow_any_instance_of(CreateConnectionAndSyncsService).to receive(:call).and_raise(StandardError.new("Connection failed"))
      end

      it "handles the error gracefully" do
        result = subject.create_connection(query: "test query")

        expect(result[:status]).to eq(:error)
        expect(result[:error]).to include("Connection failed")
      end
    end
  end

  describe "private methods" do
    describe "#extract_connection_params" do
      it "extracts connection params from the pipeline message" do
        params = subject.send(:extract_connection_params)
        expect(params["source"]["connector_id"]).to eq(connector.id)
        expect(params["source"]["streams"].pluck("name")).to eq(%w[stream1 stream2])
      end
    end

    describe "#extract_selected_streams" do
      it "returns the list of stream names" do
        params = subject.send(:extract_connection_params)
        streams = subject.send(:extract_selected_streams, params)
        expect(streams).to eq(%w[stream1 stream2])
      end
    end
  end
end
