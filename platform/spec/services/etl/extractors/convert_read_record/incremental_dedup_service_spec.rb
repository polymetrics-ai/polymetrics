# frozen_string_literal: true

require "rails_helper"

RSpec.describe Etl::Extractors::ConvertReadRecord::IncrementalDedupService do
  subject(:service) do
    described_class.new(sync_run, sync_read_record.id, record_data)
  end

  # Combine all setup into one helper
  let(:setup) do
    workspace = create(:workspace)
    destination = create(:connector, integration_type: "database")
    connection = create(:connection, workspace: workspace, destination: destination)
    sync = create(:sync, connection: connection, source_defined_primary_key: ["id"])
    sync_run = create(:sync_run, sync: sync)
    sync_read_record = create(:sync_read_record, sync: sync, sync_run: sync_run)

    {
      destination: destination,
      sync: sync,
      sync_run: sync_run,
      sync_read_record: sync_read_record
    }
  end

  let(:destination) { setup[:destination] }
  let(:sync) { setup[:sync] }
  let(:sync_run) { setup[:sync_run] }
  let(:sync_read_record) { setup[:sync_read_record] }
  let(:record_data) { [{ "id" => 1, "name" => "Test" }] }

  let(:mock_redis) do
    instance_double(Redis,
                    get: record_data.to_json,
                    sadd: true,
                    expire: true,
                    sdiff: [])
  end

  before do
    allow(Redis).to receive(:new).and_return(mock_redis)
  end

  describe "#determine_destination_action" do
    it "returns :insert for database destination" do
      expect(service.send(:determine_destination_action)).to eq(:insert)
    end

    it "returns :create for non-database destination" do
      destination.update!(integration_type: "api")
      expect(service.send(:determine_destination_action)).to eq(:create)
    end
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

  describe "#create_write_record" do
    let(:test_record) { { "id" => 1, "name" => "Test Record" } }
    let(:pk_signature) { service.send(:generate_primary_key_signature, test_record) }
    let(:data_signature) { service.send(:generate_data_signature, test_record) }

    it "adds system fields to the record" do
      write_record = service.send(:create_write_record, test_record, pk_signature, data_signature)

      expect(write_record.data["_polymetrics_id"]).to eq(data_signature)
      expect(write_record.data["_polymetrics_extracted_at"]).to be_present
    end

    it "uses data_signature as _polymetrics_id" do
      write_record = service.send(:create_write_record, test_record, pk_signature, data_signature)

      expect(write_record.data["_polymetrics_id"]).to eq(data_signature)
    end

    it "preserves original data while adding system fields" do
      write_record = service.send(:create_write_record, test_record, pk_signature, data_signature)

      expect(write_record.data["id"]).to eq(test_record["id"])
      expect(write_record.data["name"]).to eq(test_record["name"])
    end

    it "creates write record with correct signatures" do
      write_record = service.send(:create_write_record, test_record, pk_signature, data_signature)

      expect(write_record.primary_key_signature).to eq(pk_signature)
      expect(write_record.data_signature).to eq(data_signature)
    end
  end

  describe "signature generation with system fields" do
    let(:record_with_system_fields) do
      {
        "id" => 1,
        "name" => "Test",
        "_polymetrics_id" => "some-id",
        "_polymetrics_extracted_at" => Time.current.iso8601
      }
    end

    let(:record_without_system_fields) do
      {
        "id" => 1,
        "name" => "Test"
      }
    end

    it "generates same primary key signature regardless of system fields presence" do
      sig1 = service.send(:generate_primary_key_signature, record_with_system_fields)
      sig2 = service.send(:generate_primary_key_signature, record_without_system_fields)

      expect(sig1).to eq(sig2)
    end
  end
end
