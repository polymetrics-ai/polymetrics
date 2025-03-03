# frozen_string_literal: true

require "rails_helper"

RSpec.describe Etl::Extractors::ConvertReadRecord::IncrementalDedupService do
  subject(:service) do
    described_class.new(sync_run, activity)
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
  let(:activity) { instance_double("Activity", heartbeat: true) }

  let(:record_data) do
    [
      { "id" => 1, "name" => "Test 1" },
      { "id" => 2, "name" => "Test 2" }
    ]
  end

  let(:mock_redis) do
    instance_double(Redis,
                    hgetall: { sync_read_record.id.to_s => record_data.to_json },
                    hget: record_data.to_json,
                    sadd: true,
                    expire: true,
                    sdiff: [])
  end

  let(:mock_bloom_filter) do
    instance_double("BloomFilterService",
                    contains?: Hash.new(false),
                    add: true,
                    expire: true)
  end

  before do
    allow(Redis).to receive(:new).and_return(mock_redis)
    allow(BloomFilterService).to receive(:new).and_return(mock_bloom_filter)
    allow(Etl::Extractors::ConvertReadRecord::ProcessDeletionsService).to receive(:new).and_return(
      instance_double("ProcessDeletionsService", call: { success: true })
    )
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
    context "when there are no sync_read_records" do
      before do
        allow(sync_run).to receive(:sync_read_records).and_return([])
      end

      it "returns error without processing" do
        result = service.call
        expect(result).to eq({
                               success: false,
                               error: "No records found to process"
                             })
      end
    end

    context "with valid record data" do
      before do
        allow(mock_bloom_filter).to receive(:contains?).and_return(Hash.new(false))
        allow(sync_run).to receive(:sync_read_records).and_return([sync_read_record])
      end

      it "creates write records for new data" do
        expect { service.call }.to change(SyncWriteRecord, :count).by(2)
      end

      it "marks records as processed" do
        expect(SyncReadRecord).to receive(:where).with(id: sync_read_record.id).and_return(
          instance_double("ActiveRecord::Relation", update_all: true)
        )

        service.call
      end

      it "updates sync_run transformation status" do
        expect(sync_run).to receive(:update!).with(
          hash_including(
            transformation_completed: anything,
            last_transformed_at: anything
          )
        )

        service.call
      end

      context "when duplicates exist in the bloom filter" do
        before do
          # Simulate bloom filter indicating these might be duplicates
          potential_exists = {
            "#{service.send(:generate_primary_key_signature,
                            record_data.first)}:#{service.send(:generate_data_signature, record_data.first)}" => true,
            "#{service.send(:generate_primary_key_signature, record_data.last)}:#{service.send(:generate_data_signature, record_data.last)}" => false
          }
          allow(mock_bloom_filter).to receive(:contains?).and_return(potential_exists)

          # This is the key fix - make sure SyncWriteRecord.where returns records for the first item
          # which is marked as potentially existing in the bloom filter
          allow(SyncWriteRecord).to receive(:where).and_return(
            instance_double("ActiveRecord::Relation",
                            pluck: [[service.send(:generate_primary_key_signature, record_data.first),
                                     service.send(:generate_data_signature, record_data.first)]])
          )
        end

        it "verifies with database before creating records" do
          # Only the second record should be created since the first is caught by the bloom filter
          expect { service.call }.to change(SyncWriteRecord, :count).by(1)
        end
      end

      context "when exact duplicates exist in the database" do
        before do
          # Create existing record with same signatures
          existing_record_data = record_data.first
          pk_sig = service.send(:generate_primary_key_signature, existing_record_data)
          data_sig = service.send(:generate_data_signature, existing_record_data)

          create(:sync_write_record,
                 sync: sync,
                 sync_run: sync_run,
                 sync_read_record: sync_read_record,
                 data: existing_record_data,
                 primary_key_signature: pk_sig,
                 data_signature: data_sig)

          # First set up the bloom filter to indicate potential duplicates for the first record
          potential_exists = {
            "#{pk_sig}:#{data_sig}" => true,
            "#{service.send(:generate_primary_key_signature, record_data.last)}:#{service.send(:generate_data_signature, record_data.last)}" => false
          }
          allow(mock_bloom_filter).to receive(:contains?).and_return(potential_exists)

          # Then set up the database check to confirm the first record is a duplicate
          allow(SyncWriteRecord).to receive(:where).with(
            sync_id: sync.id,
            primary_key_signature: [pk_sig]
          ).and_return(
            instance_double("ActiveRecord::Relation", pluck: [[pk_sig, data_sig]])
          )

          # Allow other queries to work normally
          allow(SyncWriteRecord).to receive(:where).with(any_args).and_call_original
        end

        it "skips exact duplicates" do
          # Only the second record should be created since the first is a duplicate
          expect { service.call }.to change(SyncWriteRecord, :count).by(1)
        end
      end
    end
  end

  describe "#generate_primary_key_signature" do
    context "when primary key is missing" do
      let(:record_without_key) { { "name" => "Test" } }

      it "returns nil" do
        expect(service.send(:generate_primary_key_signature, record_without_key)).to be_nil
      end
    end

    context "with valid primary key" do
      let(:record_with_key) { { "id" => 1, "name" => "Test" } }

      it "generates consistent signature" do
        signature1 = service.send(:generate_primary_key_signature, record_with_key)
        signature2 = service.send(:generate_primary_key_signature, record_with_key)

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

  describe "handling system fields" do
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

    it "adds system fields when creating write records" do
      allow(mock_bloom_filter).to receive(:contains?).and_return(Hash.new(false))
      allow(sync_run).to receive(:sync_read_records).and_return([sync_read_record])

      service.call

      created_record = SyncWriteRecord.last
      expect(created_record.data["_polymetrics_id"]).to be_present
      expect(created_record.data["_polymetrics_extracted_at"]).to be_present
    end
  end
end
