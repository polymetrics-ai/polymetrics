# frozen_string_literal: true

# spec/services/create_connection_and_syncs_service_spec.rb
require "rails_helper"

RSpec.describe CreateConnectionAndSyncsService do
  let(:connector) { create(:connector) }
  let(:streams) { %w[stream1 stream2] }
  let(:service) { described_class.new(connector.id, streams) }

  describe "#call" do
    let(:connection_id) { 123 }
    let(:connection_service) { instance_spy(Connections::CreateService) }
    let(:syncs_service) { instance_spy(Syncs::CreateService) }

    before do
      allow(Connections::CreateService).to receive(:new)
        .with(connector.id, streams)
        .and_return(connection_service)
      allow(connection_service).to receive(:call)
        .and_return(connection_id)
      allow(Syncs::CreateService).to receive(:new)
        .with(connection_id, streams)
        .and_return(syncs_service)
      allow(syncs_service).to receive(:call)
      allow(ActiveRecord::Base).to receive(:transaction).and_yield
    end

    it "creates a connection and syncs within a transaction" do
      service.call
      expect(ActiveRecord::Base).to have_received(:transaction)
    end

    it "creates a connection using Connections::CreateService with streams" do
      service.call
      expect(Connections::CreateService).to have_received(:new).with(connector.id, streams)
    end

    it "creates syncs using Syncs::CreateService with streams" do
      service.call
      expect(Syncs::CreateService).to have_received(:new).with(connection_id, streams)
    end

    context "when streams are not provided" do
      let(:service) { described_class.new(connector.id) }

      before do
        # Override the previous mock setup for this context
        allow(Connections::CreateService).to receive(:new)
          .with(connector.id, nil)
          .and_return(connection_service)
        allow(Syncs::CreateService).to receive(:new)
          .with(connection_id, nil)
          .and_return(syncs_service)
      end

      it "creates a connection without streams" do
        service.call
        expect(Connections::CreateService).to have_received(:new).with(connector.id, nil)
      end

      it "creates syncs without streams" do
        service.call
        expect(Syncs::CreateService).to have_received(:new).with(connection_id, nil)
      end
    end

    context "when an error occurs during connection creation" do
      before do
        allow(connection_service).to receive(:call)
          .and_raise(StandardError.new("Connection creation failed"))
      end

      it "rolls back the transaction" do
        expect { service.call }.to raise_error(StandardError, "Connection creation failed")
        expect(syncs_service).not_to have_received(:call)
      end
    end

    context "when an error occurs during syncs creation" do
      before do
        allow(syncs_service).to receive(:call)
          .and_raise(StandardError.new("Syncs creation failed"))
      end

      it "rolls back the transaction" do
        expect { service.call }.to raise_error(StandardError, "Syncs creation failed")
      end
    end
  end
end
