# frozen_string_literal: true

require "rails_helper"

RSpec.describe Etl::Extractors::ConvertReadRecord::ProcessDeletionsService do
  subject(:service) do
    described_class.new(sync_run, sync_read_record_id, sync_read_record_data)
  end

  let(:connection) { create(:connection, workspace: create(:workspace)) }
  let(:sync) { create(:sync, connection: connection, source_defined_primary_key: ["id"]) }
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:previous_sync_run) { create(:sync_run, sync: sync, extraction_completed: true, created_at: 1.day.ago) }
  let(:sync_read_record) { create(:sync_read_record, sync: sync, sync_run: sync_run) }
  let(:sync_read_record_id) { sync_read_record.id }
  let(:sync_read_record_data) { [{ "id" => 2, "name" => "Current Record" }] }
  let(:deleted_signatures) { [] }

  let(:mock_redis) do
    instance_double(Redis,
                    sadd: true,
                    expire: true,
                    sdiff: deleted_signatures,
                    smembers: ["signature1"])
  end

  before do
    allow_any_instance_of(described_class).to receive(:redis).and_return(mock_redis)
    allow_any_instance_of(described_class).to receive(:previous_sync_run_id).and_return(previous_sync_run&.id)

    # Stub find_records_to_delete to avoid the DISTINCT ON PostgreSQL error
    allow_any_instance_of(described_class).to receive(:find_records_to_delete) do |service, signatures|
      records = SyncWriteRecord.where(sync_id: service.instance_variable_get(:@sync).id,
                                      primary_key_signature: signatures)

      # Group by primary_key_signature and pick the most recent one from each group
      signatures.filter_map do |sig|
        matching_records = records.select { |r| r.primary_key_signature == sig }
        matching_records.max_by(&:created_at)
      end
    end
  end

  describe "#call" do
    context "when no previous sync run exists" do
      before do
        allow(service).to receive(:previous_sync_run_id).and_return(nil)
      end

      it "returns nil without processing" do
        expect(service.call).to be_nil
      end
    end

    context "when no primary key is defined" do
      let(:sync) { create(:sync, connection: connection, source_defined_primary_key: nil) }

      it "returns nil without processing" do
        expect(service.call).to be_nil
      end
    end

    context "when previous sync run exists" do
      before do
        previous_sync_run # ensure it's created
      end

      context "when no deletions are found" do
        let(:deleted_signatures) { [] }

        it "returns nil without creating delete records" do
          expect { service.call }.not_to change(SyncWriteRecord, :count)
        end
      end

      context "when deletions are found" do
        let(:existing_records) do
          records = []
          3.times do |i|
            records << create(:sync_write_record,
                              sync: sync,
                              sync_run: previous_sync_run,
                              sync_read_record: sync_read_record,
                              data: { "id" => i + 1, "name" => "Deleted Record #{i}" },
                              primary_key_signature: "signature#{i}",
                              data_signature: "data_signature#{i}",
                              destination_action: :create,
                              status: :written,
                              created_at: Time.zone.parse("2025-03-02T03:43:15Z"))
          end
          records
        end

        let(:deleted_signatures) { existing_records.map(&:primary_key_signature) }

        before do
          existing_records # ensure they're created

          allow(mock_redis).to receive(:sdiff)
            .with(
              "sync:#{sync.id}:run:#{previous_sync_run.id}:signatures",
              "sync:#{sync.id}:run:#{sync_run.id}:signatures"
            )
            .and_return(deleted_signatures)
        end

        it "creates delete records for deleted signatures" do
          expect { service.call }.to change(SyncWriteRecord, :count).by(3)

          delete_records = SyncWriteRecord.where(sync_run_id: sync_run.id, destination_action: :delete)
          existing_records.each(&:reload) # Ensure we have fresh data from DB

          delete_records.each_with_index do |record, i|
            expected_data = existing_records[i].data.merge(
              "_polymetrics_id" => existing_records[i].data_signature
            )

            expect(record.data).to eq(expected_data)
          end
        end

        it "processes deletions in batches" do
          stub_const("Etl::Extractors::ConvertReadRecord::ProcessDeletionsService::BATCH_SIZE", 2)

          # We should expect two batch operations since we have 3 records and batch size is 2
          expect(SyncWriteRecord).to receive(:insert_all!).twice.and_call_original

          service.call
        end
      end

      context "when some signatures are already processed in the current run" do
        let(:existing_records) do
          records = []
          3.times do |i|
            records << create(:sync_write_record,
                              sync: sync,
                              sync_run: previous_sync_run,
                              sync_read_record: sync_read_record,
                              data: { "id" => i + 1, "name" => "Record #{i}" },
                              primary_key_signature: "signature#{i}",
                              data_signature: "data_signature#{i}",
                              destination_action: :create,
                              status: :written)
          end
          records
        end

        let(:deleted_signatures) { existing_records.map(&:primary_key_signature) }

        before do
          existing_records # ensure they're created

          # Create a delete record for one of the signatures in the current run
          create(:sync_write_record,
                 sync: sync,
                 sync_run: sync_run,
                 sync_read_record: sync_read_record,
                 data: existing_records.first.data,
                 primary_key_signature: existing_records.first.primary_key_signature,
                 data_signature: existing_records.first.data_signature,
                 destination_action: :delete)

          allow(mock_redis).to receive(:sdiff)
            .with(
              "sync:#{sync.id}:run:#{previous_sync_run.id}:signatures",
              "sync:#{sync.id}:run:#{sync_run.id}:signatures"
            )
            .and_return(deleted_signatures)
        end

        it "excludes already processed signatures" do
          expect { service.call }.to change(SyncWriteRecord, :count).by(2)

          # We should have 3 records in the current run (1 that was pre-created + 2 new ones)
          expect(SyncWriteRecord.where(sync_run_id: sync_run.id).count).to eq(3)
        end
      end

      context "when multiple versions of a record exist" do
        let(:signature) { "duplicate_signature" }
        let(:older_record) do
          create(:sync_write_record,
                 sync: sync,
                 sync_run: previous_sync_run,
                 sync_read_record: sync_read_record,
                 data: { "id" => 1, "name" => "Older Version" },
                 primary_key_signature: signature,
                 data_signature: "data_signature1",
                 destination_action: :create,
                 status: :written,
                 created_at: 2.days.ago)
        end

        let(:newer_record) do
          create(:sync_write_record,
                 sync: sync,
                 sync_run: previous_sync_run,
                 sync_read_record: sync_read_record,
                 data: { "id" => 1, "name" => "Newer Version" },
                 primary_key_signature: signature,
                 data_signature: "data_signature2",
                 destination_action: :create,
                 status: :written,
                 created_at: 1.day.ago)
        end

        let(:deleted_signatures) { [signature] }

        before do
          older_record # ensure it's created
          newer_record # ensure it's created

          allow(mock_redis).to receive(:sdiff)
            .with(
              "sync:#{sync.id}:run:#{previous_sync_run.id}:signatures",
              "sync:#{sync.id}:run:#{sync_run.id}:signatures"
            )
            .and_return(deleted_signatures)
        end

        it "uses the most recent version of each record for deletion" do
          expect { service.call }.to change(SyncWriteRecord, :count).by(1)

          delete_record = SyncWriteRecord.where(sync_run_id: sync_run.id, destination_action: :delete).first
          newer_record.reload # Refresh from database

          expected_data = newer_record.data.merge(
            "_polymetrics_id" => newer_record.data_signature
          )

          expect(delete_record.data).to eq(expected_data)
        end
      end
    end
  end

  describe "#previous_sync_run_id" do
    before do
      # Completely replace the implementation to enable proper testing
      allow_any_instance_of(described_class).to receive(:previous_sync_run_id).and_call_original

      # Clear existing sync runs to ensure test isolation
      sync.sync_runs.delete_all
    end

    context "when previous completed sync runs exist" do
      let(:older_sync_run) do
        create(:sync_run,
               sync: sync,
               extraction_completed: true,
               created_at: 2.days.ago)
      end

      let(:newer_sync_run) do
        create(:sync_run,
               sync: sync,
               extraction_completed: true,
               created_at: 1.day.ago)
      end

      it "returns the most recent completed sync run id" do
        older_sync_run
        newer_sync_run
        expect(service.send(:previous_sync_run_id)).to eq(newer_sync_run.id)
      end
    end

    context "when no previous completed sync runs exist" do
      before do
        create(:sync_run,
               sync: sync,
               extraction_completed: false,
               created_at: 1.day.ago)
      end

      it "returns nil" do
        expect(service.send(:previous_sync_run_id)).to be_nil
      end
    end
  end

  describe "Redis key management" do
    it "generates correct current sync run key" do
      expected_key = "sync:#{sync.id}:run:#{sync_run.id}:signatures"
      expect(service.send(:current_sync_run_key)).to eq(expected_key)
    end

    context "when previous sync run exists" do
      before do
        allow(service).to receive(:previous_sync_run_id).and_return(previous_sync_run.id)
      end

      it "generates correct previous sync run key" do
        expected_key = "sync:#{sync.id}:run:#{previous_sync_run.id}:signatures"
        expect(service.send(:previous_sync_run_key)).to eq(expected_key)
      end
    end
  end
end
