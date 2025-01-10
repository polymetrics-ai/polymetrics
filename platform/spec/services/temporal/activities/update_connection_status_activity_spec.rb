# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::UpdateConnectionStatusActivity do
  subject { described_class.new(context) }

  let(:context) { instance_double("Temporal::Activity::Context", logger: logger) }
  let(:logger) { instance_double("Logger", error: nil) }
  let(:connection) { create(:connection) }

  describe "#execute" do
    context "when status is completed" do
      it "updates connection status to healthy" do
        allow(Connection).to receive(:find).with(connection.id).and_return(connection)
        allow(connection).to receive(:update!).with(status: "healthy")

        result = subject.execute(
          connection_id: connection.id,
          status: :completed
        )

        expect(result).to eq({
                               success: true,
                               status: "healthy"
                             })
      end
    end

    context "when status is failed" do
      it "updates connection status to failed" do
        allow(Connection).to receive(:find).with(connection.id).and_return(connection)
        allow(connection).to receive(:update!).with(status: "failed")

        result = subject.execute(
          connection_id: connection.id,
          status: :failed,
          message: "Error message"
        )

        expect(result).to eq({
                               success: false,
                               status: "failed",
                               error: "Error message"
                             })
      end
    end

    context "when status is partial_success" do
      it "updates connection status to healthy with warning" do
        allow(Connection).to receive(:find).with(connection.id).and_return(connection)
        allow(connection).to receive(:update!).with(status: "healthy")

        result = subject.execute(
          connection_id: connection.id,
          status: :partial_success,
          message: "Warning message"
        )

        expect(result).to eq({
                               success: true,
                               status: "healthy",
                               warning: "Warning message"
                             })
      end
    end

    context "when connection not found" do
      before do
        allow(Connection).to receive(:find).with(connection.id)
                                           .and_raise(ActiveRecord::RecordNotFound.new("Couldn't find Connection with 'id'=#{connection.id}"))
      end

      it "returns error status" do
        result = subject.execute(
          connection_id: connection.id,
          status: :completed
        )

        expect(result).to eq({
                               success: false,
                               status: "error",
                               error: "Couldn't find Connection with 'id'=#{connection.id}"
                             })
      end
    end

    context "when update fails" do
      before do
        allow(Connection).to receive(:find).with(connection.id).and_return(connection)
        allow(connection).to receive(:update!)
          .and_raise(ActiveRecord::RecordInvalid.new(connection))
      end

      it "returns error status" do
        result = subject.execute(
          connection_id: connection.id,
          status: :completed
        )

        expect(result).to eq({
                               success: false,
                               status: "error",
                               error: "Validation failed: "
                             })
      end
    end

    context "with invalid status" do
      it "returns error with invalid status message" do
        allow(Connection).to receive(:find).with(connection.id).and_return(connection)

        result = subject.execute(
          connection_id: connection.id,
          status: :invalid_status
        )

        expect(result).to eq({
                               success: false,
                               status: "error",
                               error: "Invalid connection status: invalid_status"
                             })
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
