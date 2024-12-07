# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::UpdateConnectionStatusActivity do
  subject { described_class.new(context) }

  let(:context) { instance_double("Temporal::Activity::Context", logger: logger) }
  let(:logger) { instance_double("Logger") }
  let(:connection) { create(:connection) }

  before do
    allow(Connection).to receive(:find).with(connection.id).and_return(connection)
    allow(logger).to receive(:error)
  end

  describe "#execute" do
    context "when status is completed" do
      it "updates connection status to healthy" do
        expect(connection).to receive(:update).with(status: "healthy")

        subject.execute(
          connection_id: connection.id,
          status: :completed
        )
      end
    end

    context "when status is failed" do
      it "updates connection status to failed" do
        expect(connection).to receive(:update).with(status: "failed")

        subject.execute(
          connection_id: connection.id,
          status: :failed
        )
      end
    end

    context "when connection not found" do
      before do
        allow(Connection).to receive(:find).with(connection.id)
                                           .and_raise(ActiveRecord::RecordNotFound)
      end

      it "raises RecordNotFound error" do
        expect do
          subject.execute(
            connection_id: connection.id,
            status: :completed
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when update fails" do
      before do
        allow(connection).to receive(:update)
          .and_raise(ActiveRecord::RecordInvalid.new(connection))
      end

      it "raises the error" do
        expect do
          subject.execute(
            connection_id: connection.id,
            status: :completed
          )
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "with invalid status" do
      it "raises ArgumentError" do
        expect do
          subject.execute(
            connection_id: connection.id,
            status: :invalid_status
          )
        end.to raise_error(ArgumentError, /Invalid status/)
      end
    end
  end

  describe "retry policy" do
    it "configures correct retry settings" do
      retry_policy = described_class.instance_variable_get(:@retry_policy)

      expect(retry_policy).to include(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )
    end
  end
end
