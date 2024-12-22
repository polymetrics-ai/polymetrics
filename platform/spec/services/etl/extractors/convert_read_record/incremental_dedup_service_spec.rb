# frozen_string_literal: true

require "rails_helper"

RSpec.describe Etl::Extractors::ConvertReadRecord::IncrementalDedupService do
  subject(:service) do
    described_class.new(sync_run, sync_read_record_id, record_data)
  end

  let(:workspace) { create(:workspace) }
  let(:connection) { create(:connection, workspace: workspace) }
  let(:sync) { create(:sync, connection: connection, source_defined_primary_key: ["id"]) }
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:sync_read_record) { create(:sync_read_record, sync: sync, sync_run: sync_run) }
  let(:sync_read_record_id) { sync_read_record.id }
  let(:record_data) { [{ "id" => 1, "name" => "Test" }] }

  # Mock Redis for all tests
  let(:mock_redis) do
    instance_double(Redis,
                    sadd: true,
                    expire: true,
                    sdiff: [])
  end

  before do
    allow_any_instance_of(described_class).to receive(:redis).and_return(mock_redis)
  end

  describe "#call" do
    context "when sync_read_record_data is not an array" do
      let(:record_data) { "invalid" }

      it "returns nil without processing" do
        expect(service.call).to be_nil
      end
    end

    context "with valid record data" do
      let(:record_data) do
        [
          { "id" => 1, "name" => "Test 1" },
          { "id" => 2, "name" => "Test 2" }
        ]
      end

      it "creates write records for new data" do
        expect { service.call }.to change(SyncWriteRecord, :count).by(2)
      end

      context "when duplicate records exist" do
        before do
          # Create existing record with same signatures
          existing_record_data = { "id" => 1, "name" => "Test 1" }
          pk_sig = service.send(:generate_primary_key_signature, existing_record_data)
          data_sig = service.send(:generate_data_signature, existing_record_data)

          create(:sync_write_record,
                 sync: sync,
                 sync_run: sync_run,
                 sync_read_record: sync_read_record,
                 data: existing_record_data,
                 primary_key_signature: pk_sig,
                 data_signature: data_sig)
        end

        it "skips exact duplicates" do
          expect { service.call }.to change(SyncWriteRecord, :count).by(1)
        end
      end
    end
  end

  describe "#generate_primary_key_signature" do
    context "when primary key is missing" do
      let(:record_data) { [{ "name" => "Test" }] }

      it "returns nil" do
        expect(service.send(:generate_primary_key_signature, record_data.first)).to be_nil
      end
    end

    context "with valid primary key" do
      let(:record_data) { [{ "id" => 1, "name" => "Test" }] }

      it "generates consistent signature" do
        signature1 = service.send(:generate_primary_key_signature, record_data.first)
        signature2 = service.send(:generate_primary_key_signature, record_data.first)

        expect(signature1).to eq(signature2)
      end
    end
  end

  describe "#generate_data_signature" do
    it "generates different signatures for different data" do
      data1 = { "id" => 1, "name" => "Test 1" }
      data2 = { "id" => 1, "name" => "Test 2" }

      sig1 = service.send(:generate_data_signature, data1)
      sig2 = service.send(:generate_data_signature, data2)

      expect(sig1).not_to eq(sig2)
    end

    it "generates consistent signatures regardless of hash key order" do
      data1 = { "id" => 1, "name" => "Test" }
      data2 = { "name" => "Test", "id" => 1 }

      sig1 = service.send(:generate_data_signature, data1)
      sig2 = service.send(:generate_data_signature, data2)

      expect(sig1).to eq(sig2)
    end
  end

  describe "#determine_destination_action" do
    context "when destination is database" do
      let(:destination) { create(:connector, integration_type: "database", connector_class_name: "database") }
      let(:connection) { create(:connection, workspace: workspace, destination: destination) }
      let(:sync) { create(:sync, connection: connection, source_defined_primary_key: ["id"]) }

      it "returns :insert" do
        expect(service.send(:determine_destination_action)).to eq(:insert)
      end
    end

    context "when destination is not database" do
      let(:destination) { create(:connector, integration_type: "api", connector_class_name: "github") }
      let(:connection) { create(:connection, workspace: workspace, destination: destination) }
      let(:sync) { create(:sync, connection: connection, source_defined_primary_key: ["id"]) }

      it "returns :create" do
        expect(service.send(:determine_destination_action)).to eq(:create)
      end
    end
  end
end