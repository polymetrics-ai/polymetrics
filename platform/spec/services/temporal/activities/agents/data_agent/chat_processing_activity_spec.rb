# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::Agents::DataAgent::ChatProcessingActivity do
  let(:chat) { create(:chat) }
  let(:activity_context) { instance_double("Temporal::Activity::Context", logger: Rails.logger) }
  let(:activity) { described_class.new(activity_context) }
  let(:content) { "Test response" }
  let(:tool_calls) { [{ "name" => "test_tool" }] }

  describe "#execute" do
    context "when processing succeeds" do
      it "creates a success message" do
        expect do
          activity.execute(chat_id: chat.id, content: content)
        end.to change(chat.messages, :count).by(1)

        message = chat.messages.last
        expect(message.content).to eq(content)
        expect(message.role).to eq("assistant")
      end

      it "updates tool calls when present" do
        activity.execute(chat_id: chat.id, content: content, tool_calls: tool_calls)
        expect(chat.reload.tool_call_data).to eq(tool_calls)
      end
    end

    context "when processing fails" do
      let(:error_message) { "Test error" }

      it "creates an error message" do
        expect do
          activity.execute(chat_id: chat.id, status: :error, error_message: error_message)
        end.to change(chat.messages, :count).by(1)

        message = chat.messages.last
        expect(message.content).to include(error_message)
        expect(message.role).to eq("system")
      end

      it "marks chat as failed" do
        activity.execute(chat_id: chat.id, status: :error, error_message: error_message)
        expect(chat.reload.status).to eq("failed")
      end
    end

    context "when exception occurs" do
      before do
        allow(Chat).to receive(:find).and_raise(StandardError.new("DB failure"))
      end

      it "returns error status" do
        result = activity.execute(chat_id: chat.id)
        expect(result[:status]).to eq(:error)
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Failed to save chat response/)
        activity.execute(chat_id: chat.id)
      end
    end
  end

  describe "configuration" do
    it "has correct timeouts" do
      expect(described_class.instance_variable_get(:@timeouts))
        .to eq(start_to_close: 36_000)
    end
  end
end
