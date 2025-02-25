# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::Agents::DataAgent::CheckConnectionHealthActivity do
  subject(:activity) { described_class.new(activity_context) }

  let(:activity_context) { instance_double("Temporal::Activity::Context", logger: logger) }
  let(:logger) { instance_double("Logger", error: nil) }
  let(:chat) { create(:chat) }

  describe "#execute" do
    context "when chat has healthy connections with recent syncs" do
      let(:connection1) { create(:connection, status: :healthy) }
      let(:connection2) { create(:connection, status: :healthy) }
      let(:sync1) { create(:sync, connection: connection1) }
      let(:sync2) { create(:sync, connection: connection2) }

      before do
        chat.connections << [connection1, connection2]

        create(:sync_run,
               sync: sync1,
               started_at: 20.minutes.ago,
               status: :succeeded)

        create(:sync_run,
               sync: sync2,
               started_at: 50.minutes.ago,
               status: :succeeded)

        connection1.syncs.last.sync_runs.last.update(completed_at: 15.minutes.ago)
        connection2.syncs.last.sync_runs.last.update(completed_at: 45.minutes.ago)
      end

      it "returns only connection IDs with recent syncs" do
        result = activity.execute(chat_id: chat.id)

        expect(result).to eq({
                               recently_synced_healthy_connection_ids: [connection1.id]
                             })
      end
    end

    context "when chat has no healthy connections" do
      let(:connection) { create(:connection, status: :failed) }

      before do
        chat.connections << connection
      end

      it "returns empty array" do
        result = activity.execute(chat_id: chat.id)

        expect(result).to eq({
                               recently_synced_healthy_connection_ids: []
                             })
      end
    end

    context "when chat has healthy connections but no recent syncs" do
      let(:connection) { create(:connection, status: :healthy) }
      let(:sync) { create(:sync, connection: connection) }

      before do
        chat.connections << connection
        create(:sync_run,
               sync: sync,
               started_at: 2.5.hours.ago,
               status: :succeeded)
        connection.syncs.last.sync_runs.last.update(completed_at: 2.hours.ago)
      end

      it "returns empty array" do
        result = activity.execute(chat_id: chat.id)

        expect(result).to eq({
                               recently_synced_healthy_connection_ids: []
                             })
      end
    end

    context "when chat has no connections" do
      it "returns empty array" do
        result = activity.execute(chat_id: chat.id)

        expect(result).to eq({
                               recently_synced_healthy_connection_ids: []
                             })
      end
    end

    context "when chat does not exist" do
      it "returns empty array" do
        result = activity.execute(chat_id: -1)

        expect(result).to eq({
                               recently_synced_healthy_connection_ids: []
                             })
      end
    end
  end
end
