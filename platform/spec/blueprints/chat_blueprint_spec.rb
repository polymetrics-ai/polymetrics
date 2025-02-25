# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatBlueprint do
  let(:workspace) { create(:workspace) }
  let(:user) { create(:user) }
  let(:source) { create(:connector) }
  let(:connection) { create(:connection, source: source) }

  let(:chat) do
    create(:chat,
           workspace: workspace,
           user: user,
           title: "Test Chat",
           description: "Test Description",
           connections: [connection]).tap do |c|
      create(:message,
             chat: c,
             content: '{"steps": ["step1", "step2"]}',
             message_type: "pipeline")
      create(:message, chat: c, content: "Regular message", message_type: "text")
    end
  end

  describe "default view" do
    let(:blueprint) { described_class.render(chat) }
    let(:parsed) { JSON.parse(blueprint) }

    it "includes basic fields" do
      expect(parsed).to include(
        "id" => chat.id,
        "title" => "Test Chat",
        "status" => chat.status,
        "created_at" => chat.created_at.utc.to_s,
        "description" => "Test Description"
      )
    end

    it "calculates icon_url from first connection" do
      expect(parsed["icon_url"]).to eq("https://raw.githubusercontent.com/polymetrics-ai/polymetrics/main/public/connector_icons/github.svg")
    end

    it "uses default icon when no connections" do
      chat.connections = []
      expect(parsed["icon_url"]).to eq("/icon-data-agent.svg")
    end

    it "calculates message_count" do
      expect(parsed["message_count"]).to eq(2)
    end

    it "formats last_message with parsed content for pipelines" do
      chat.messages.create!(
        content: '{"steps": ["step1", "step2"]}',
        message_type: "pipeline",
        role: "system"
      )

      blueprint = described_class.render(chat)
      parsed = JSON.parse(blueprint)

      last_message = parsed["last_message"]
      expect(last_message["content"]).to eq({ "steps" => %w[step1 step2] })
      expect(last_message["message_type"]).to eq("pipeline")
    end
  end

  describe "history view" do
    let(:blueprint) { described_class.render(chat, view: :history) }
    let(:parsed) { JSON.parse(blueprint) }

    it "includes history-specific fields" do
      expect(parsed).to include(
        "id" => chat.id,
        "title" => "Test Chat",
        "status" => chat.status,
        "created_at" => chat.created_at.utc.to_s,
        "description" => "Test Description",
        "message_count" => 2
      )
    end

    it "handles messages without pipeline content" do
      chat.messages.last.update!(content: "Plain text")
      last_message = parsed["last_message"]
      expect(last_message["content"]).to eq("Plain text")
    end
  end

  describe "chat view" do
    let(:blueprint) { described_class.render(chat, view: :chat, workflow_id: "test_123") }
    let(:parsed) { JSON.parse(blueprint) }

    it "includes workflow_id from options" do
      expect(parsed["workflow_id"]).to eq("test_123")
    end
  end

  describe "parse_content" do
    it "parses valid pipeline JSON" do
      content = '{"steps": ["step1"]}'
      message = build(:message, message_type: "pipeline", content: content)
      expect(described_class.parse_content(message)).to eq({ "steps" => ["step1"] })
    end

    it "returns raw content for invalid JSON" do
      content = "invalid json"
      message = build(:message, message_type: "pipeline", content: content)
      expect(described_class.parse_content(message)).to eq(content)
    end

    it "returns raw content for non-pipeline messages" do
      content = "plain text"
      message = build(:message, message_type: "text", content: content)
      expect(described_class.parse_content(message)).to eq(content)
    end
  end

  describe "render_with_data" do
    it "wraps response in data key" do
      result = described_class.render_with_data(chat)

      expect(result[:data]).to have_key("id")
    end
  end
end
