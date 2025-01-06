# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connections::StartDataSyncService do
  describe "#call" do
    let(:connection) { create(:connection) }
    let(:service) { described_class.new(connection) }
    let(:workflow_id) { "connection_data_sync_connection_id_#{connection.id}" }
    let(:workflow_options) do
      {
        workflow_id: workflow_id,
        task_queue: "platform_queue",
        workflow_execution_timeout: 86_400
      }
    end

    before do
      allow(Temporal).to receive(:start_workflow)
    end

    it "starts the connection" do
      expect(connection).to receive(:start!)
      service.call
    end

    it "starts the temporal workflow" do
      expect(Temporal).to receive(:start_workflow).with(
        Temporal::Workflows::ConnectionDataSyncWorkflow,
        connection.id,
        options: workflow_options
      )

      service.call
    end

    it "generates the correct workflow_id" do
      service.call
      expect(Temporal).to have_received(:start_workflow).with(
        anything,
        anything,
        options: hash_including(workflow_id: workflow_id)
      )
    end

    context "when connection fails to start" do
      before do
        error = AASM::InvalidTransition.new(
          connection, # object
          :start,              # event_name
          :default,            # state_machine_name (use default instead of :aasm)
          ["cannot transition from 'created' to 'running'"] # failures
        )
        allow(connection).to receive(:start!).and_raise(error)
      end

      it "raises the error" do
        expect { service.call }.to raise_error(AASM::InvalidTransition)
      end

      it "does not start the workflow" do
        expect(Temporal).not_to receive(:start_workflow)
        expect { service.call }.to raise_error(AASM::InvalidTransition)
      end
    end

    context "when temporal workflow fails to start" do
      before do
        allow(Temporal).to receive(:start_workflow).and_raise(StandardError)
      end

      it "raises the error" do
        expect { service.call }.to raise_error(StandardError)
      end

      it "still transitions the connection state" do
        expect(connection).to receive(:start!)
        expect { service.call }.to raise_error(StandardError)
      end
    end
  end
end
