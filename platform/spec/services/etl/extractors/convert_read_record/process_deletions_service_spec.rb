# frozen_string_literal: true

require "rails_helper"

RSpec.describe Etl::Extractors::ConvertReadRecord::ProcessDeletionsService do
  subject(:service) do
    described_class.new(sync_run, sync_read_record_id, sync_read_record_data)
  end

  let(:connection) { create(:connection, workspace: create(:workspace)) }
  let(:sync) { create(:sync, connection: connection, source_defined_primary_key: ["id"]) }
  let(:sync_run) { create(:sync_run, sync: sync) }
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
      let(:previous_sync_run) { create(:sync_run, sync: sync, extraction_completed: true) }

      before do
        allow(service).to receive(:previous_sync_run_id).and_return(previous_sync_run.id)
      end

      context "when no deletions are found" do
        let(:deleted_signatures) { [] }

        it "returns nil without creating delete records" do
          expect { service.call }.not_to change(SyncWriteRecord, :count)
        end
      end

      context "when deletions are found" do
        let(:existing_record) do
          create(:sync_write_record,
                 sync: sync,
                 sync_run: previous_sync_run,
                 sync_read_record: sync_read_record,
                 data: { "id" => 1, "name" => "Deleted Record" },
                 destination_action: :create,
                 status: :written)
        end

        let(:deleted_signatures) { [existing_record.primary_key_signature] }

        before do
          allow(mock_redis).to receive(:sdiff)
            .with(
              "sync:#{sync.id}:run:#{previous_sync_run.id}:pk_signatures",
              "sync:#{sync.id}:run:#{sync_run.id}:pk_signatures"
            )
            .and_return(deleted_signatures)
        end

        it "creates delete records for deleted signatures" do
          expect { service.call }.to change(SyncWriteRecord, :count).by(1)

          delete_record = SyncWriteRecord.last
          expect(delete_record.destination_action).to eq("delete")
          expect(delete_record.primary_key_signature).to eq(existing_record.primary_key_signature)
          expect(delete_record.data).to eq(existing_record.data)
          expect(delete_record.sync_read_record_id).to eq(sync_read_record_id)
        end
      end

      context "when deletions are found but already processed" do
        let(:existing_record) do
          create(:sync_write_record,
                 sync: sync,
                 sync_run: previous_sync_run,
                 sync_read_record: sync_read_record,
                 data: { "id" => 1, "name" => "Deleted Record" },
                 destination_action: :create,
                 status: :written)
        end

        let(:deleted_signatures) { [existing_record.primary_key_signature] }

        before do
          allow(mock_redis).to receive(:sdiff)
            .with(
              "sync:#{sync.id}:run:#{previous_sync_run.id}:pk_signatures",
              "sync:#{sync.id}:run:#{sync_run.id}:pk_signatures"
            )
            .and_return(deleted_signatures)

          create(:sync_write_record,
                 sync: sync,
                 sync_run: sync_run,
                 sync_read_record: sync_read_record,
                 data: { "id" => 1, "name" => "Deleted Record" },
                 destination_action: :delete)
        end

        it "skips already processed signatures" do
          expect { service.call }.not_to change(SyncWriteRecord, :count)
        end
      end
    end
  end

  describe "#previous_sync_run_id" do
    context "when previous completed sync runs exist" do
      let(:newer_sync_run) do
        create(:sync_run,
               sync: sync,
               extraction_completed: true,
               created_at: 1.day.ago)
      end

      before do
        create(:sync_run,
               sync: sync,
               extraction_completed: true,
               created_at: 2.days.ago)
        newer_sync_run
      end

      it "returns the most recent completed sync run id" do
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
      expected_key = "sync:#{sync.id}:run:#{sync_run.id}:pk_signatures"
      expect(service.send(:current_sync_run_key)).to eq(expected_key)
    end

    context "when previous sync run exists" do
      let(:previous_sync_run) { create(:sync_run, sync: sync) }

      before do
        allow(service).to receive(:previous_sync_run_id).and_return(previous_sync_run.id)
      end

      it "generates correct previous sync run key" do
        expected_key = "sync:#{sync.id}:run:#{previous_sync_run.id}:pk_signatures"
        expect(service.send(:previous_sync_run_key)).to eq(expected_key)
      end
    end

    context "when no previous sync run exists" do
      before do
        allow(service).to receive(:previous_sync_run_id).and_return(nil)
      end

      it "returns nil for previous sync run key" do
        expect(service.send(:previous_sync_run_key)).to be_nil
      end
    end
  end
end
