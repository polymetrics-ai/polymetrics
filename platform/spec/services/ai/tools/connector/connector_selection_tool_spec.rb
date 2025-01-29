# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ai::Tools::Connector::ConnectorSelectionTool do
  subject { described_class.new(workspace_id: workspace.id, chat_id: chat.id, original_query: original_query) }

  let(:workspace) { create(:workspace) }
  let(:chat) { create(:chat, workspace: workspace) }
  let(:connector1) { create(:connector, workspace: workspace, configuration: { repository_name: "rails/rails" }, connector_class_name: "github") }
  let(:connector2) { create(:connector, workspace: workspace, connector_class_name: "duckdb") }
  let(:connector3) { workspace.default_analytics_db }
  let(:original_query) { "Please identify how many people starred my rails repo in Github?" }

  before do
    connector1
    connector2
    connector3
  end

  describe "#find_connectors" do
    context "with valid connectors" do
      it "creates pipeline messages with connector selection" do
        VCR.use_cassette("connector_selection/successful_selection", record: :once) do
          result = subject.find_connectors(query: original_query)

          expect(result[:status]).to eq(:success)
          expect(chat.messages.pipeline).to exist
          expect(chat.pipelines).to exist
        end
      end
    end

    context "when no connectors exist" do
      before do
        Connector.destroy_all
      end

      it "returns an error message" do
        VCR.use_cassette("connector_selection/no_connectors", record: :once) do
          result = subject.find_connectors(query: original_query)

          expect(result[:status]).to eq(:error)
          expect(result[:error]).to include("No connectors found")
        end
      end
    end
  end

  describe "private methods" do
    describe "#fetch_workspace_connectors" do
      it "returns connectors for the workspace" do
        connectors = subject.send(:fetch_workspace_connectors)

        expect(connectors).to contain_exactly(connector1, connector2, connector3)
      end
    end

    describe "#create_prompt_text" do
      it "generates a valid prompt with connectors" do
        prompt = subject.send(:create_prompt_text, [connector1, connector2, connector3], original_query)

        expect(prompt).to include(original_query)
      end
    end
  end
end
