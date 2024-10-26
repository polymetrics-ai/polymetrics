# spec/services/create_connection_and_syncs_service_spec.rb
require 'rails_helper'

RSpec.describe CreateConnectionAndSyncsService do
  let(:connector) { create(:connector) }
  let(:service) { described_class.new(connector.id) }

  describe '#call' do
    let(:connection_id) { 123 }
    let(:connection_service) { instance_double(Connections::CreateService) }
    let(:syncs_service) { instance_double(Syncs::CreateService) }

    before do
      allow(Connections::CreateService).to receive(:new).with(connector.id).and_return(connection_service)
      allow(connection_service).to receive(:call).and_return(connection_id)
      allow(Syncs::CreateService).to receive(:new).with(connection_id).and_return(syncs_service)
      allow(syncs_service).to receive(:call)
    end

    it 'creates a connection and syncs within a transaction' do
      expect(ActiveRecord::Base).to receive(:transaction).and_yield
      service.call
    end

    it 'creates a connection using Connections::CreateService' do
      expect(connection_service).to receive(:call)
      service.call
    end

    it 'creates syncs using Syncs::CreateService' do
      expect(syncs_service).to receive(:call)
      service.call
    end

    it 'passes the correct connection_id to Syncs::CreateService' do
      expect(Syncs::CreateService).to receive(:new).with(connection_id)
      service.call
    end

    context 'when an error occurs during connection creation' do
      before do
        allow(connection_service).to receive(:call).and_raise(StandardError.new("Connection creation failed"))
      end

      it 'rolls back the transaction' do
        expect { service.call }.to raise_error(StandardError, "Connection creation failed")
        expect(syncs_service).not_to have_received(:call)
      end
    end

    context 'when an error occurs during syncs creation' do
      before do
        allow(syncs_service).to receive(:call).and_raise(StandardError.new("Syncs creation failed"))
      end

      it 'rolls back the transaction' do
        expect { service.call }.to raise_error(StandardError, "Syncs creation failed")
      end
    end
  end
end