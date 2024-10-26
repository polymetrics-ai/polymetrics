# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Connections::CreateService do
  let(:workspace) { create(:workspace) }
  let(:source_connector) { create(:connector, workspace: workspace) }
  let(:destination_connector) { create(:connector, workspace: workspace, default_analytics_db: true) }
  let(:service) { described_class.new(source_connector.id) }

  before do
    allow(workspace).to receive(:default_analytics_db).and_return(destination_connector)
  end

  describe '#call' do
    it 'creates a new connection' do
      expect { service.call }.to change(Connection, :count).by(1)
    end

    it 'returns the id of the created connection' do
      connection_id = service.call
      expect(connection_id).to be_a(Integer)
      expect(Connection.find(connection_id)).to be_present
    end

    it 'sets the correct attributes for the connection' do
      connection_id = service.call
      connection = Connection.find(connection_id)

      expect(connection).to have_attributes(
        workspace: workspace,
        source: source_connector,
        destination: destination_connector,
        name: "#{source_connector.name} Connection",
        schedule_type: 'manual',
        status: 'created',
        sync_frequency: 'hourly',
        namespace: 'system_defined'
      )
    end

    it 'sets the correct configuration for the connection' do
      connection_id = service.call
      connection = Connection.find(connection_id)

      expect(connection.configuration).to eq(
        {
          'source' => source_connector.configuration,
          'destination' => destination_connector.configuration
        }
      )
    end

    context 'when the connector is not found' do
      let(:service) { described_class.new(-1) }

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end