# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::ConvertReadRecordActivity do
  let(:activity) { described_class.new(double("context")) }
  let(:sync) { create(:sync) }
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:sync_read_record) { create(:sync_read_record, sync: sync, sync_run: sync_run) }

  describe "#execute" do
    context "when sync_run is already completed" do
      before do
        sync_run.update(extraction_completed: true)
      end

      it "returns early without processing records" do
        expect(activity).not_to receive(:process_read_records)
        activity.execute(sync_run.id)
      end
    end

    context "when sync_run has no read records" do
      it "returns early without processing records" do
        expect(activity).not_to receive(:process_read_records)
        activity.execute(sync_run.id)
      end
    end

    context "when sync_run has read records to process" do
      context "with incremental_dedup sync" do
        let(:sync) { create(:sync, sync_mode: :incremental_dedup) }
        let!(:sync_read_record) do
          create(:sync_read_record, sync: sync, sync_run: sync_run, data: [{ "id" => 1, "name" => "Test" }])
        end

        let(:mock_incremental_service) { instance_double(Etl::Extractors::ConvertReadRecord::IncrementalDedupService) }
        let(:mock_deletions_service) { instance_double(Etl::Extractors::ConvertReadRecord::ProcessDeletionsService) }

        before do
          allow(Etl::Extractors::ConvertReadRecord::IncrementalDedupService)
            .to receive(:new)
            .and_return(mock_incremental_service)
          allow(mock_incremental_service).to receive(:call)

          allow(Etl::Extractors::ConvertReadRecord::ProcessDeletionsService)
            .to receive(:new)
            .and_return(mock_deletions_service)
          allow(mock_deletions_service).to receive(:call)
        end

        it "processes records using incremental dedup service" do
          activity.execute(sync_run.id)
          expect(mock_incremental_service).to have_received(:call)
          expect(mock_deletions_service).to have_received(:call)
        end
      end

      context "with full refresh sync" do
        let!(:sync_read_record) do
          create(:sync_read_record, sync: sync, sync_run: sync_run, data: [{ "key" => "value" }])
        end

        it "processes records and updates sync_run status" do
          activity.execute(sync_run.id)

          sync_run.reload
          expect(sync_run.extraction_completed).to be true
          expect(sync_run.last_extracted_at).to be_present
          expect(sync_run.records_extracted).to eq(1)
        end

        it "creates write records for each data entry" do
          expect do
            activity.execute(sync_run.id)
          end.to change(SyncWriteRecord, :count).by(1)
        end

        it "marks read record as extracted" do
          activity.execute(sync_run.id)

          sync_read_record.reload
          expect(sync_read_record.extraction_completed_at).to be_present
        end
      end
    end
  end

  describe "#create_write_records" do
    context "with invalid data format" do
      let!(:sync_read_record) { create(:sync_read_record, sync: sync, sync_run: sync_run, data: "invalid") }

      it "logs error and skips record creation" do
        expect(Rails.logger).to receive(:error).with("Invalid data format for sync_read_record #{sync_read_record.id}")

        expect do
          activity.send(:create_write_records, sync_read_record)
        end.not_to change(SyncWriteRecord, :count)
      end
    end

    context "with empty data" do
      let!(:sync_read_record) do
        create(:sync_read_record,
               sync: sync,
               sync_run: sync_run,
               data: [{ "test" => "initial" }])
      end

      before do
        sync_read_record.update_column(:data, "[]")
      end

      it "skips record creation" do
        expect do
          activity.send(:create_write_records, sync_read_record)
        end.not_to change(SyncWriteRecord, :count)
      end
    end

    context "with valid array data" do
      let!(:sync_read_record) do
        create(:sync_read_record, sync: sync, sync_run: sync_run,
                                  data: [{ "key1" => "value1" }, { "key2" => "value2" }])
      end

      it "creates write records for each data entry" do
        expect do
          activity.send(:create_write_records, sync_read_record)
        end.to change(SyncWriteRecord, :count).by(2)
      end

      it "creates write records with correct associations" do
        activity.send(:create_write_records, sync_read_record)

        write_record = SyncWriteRecord.last
        expect(write_record.sync).to eq(sync)
        expect(write_record.sync_run).to eq(sync_run)
        expect(write_record.sync_read_record).to eq(sync_read_record)
        expect(write_record.data).to be_present
      end
    end
  end

  describe "#all_records_extracted?" do
    let!(:sync_read_record1) do
      create(:sync_read_record,
             sync: sync,
             sync_run: sync_run,
             data: [{ "test" => "record1" }])
    end

    let!(:sync_read_record2) do
      create(:sync_read_record,
             sync: sync,
             sync_run: sync_run,
             data: [{ "test" => "record2" }])
    end

    it "returns false when not all records are extracted" do
      sync_read_record1.update(extraction_completed_at: Time.current)

      result = activity.send(:all_records_extracted?, sync_run.sync_read_records)
      expect(result).to be false
    end

    it "returns true when all records are extracted" do
      sync_read_record1.update(extraction_completed_at: Time.current)
      sync_read_record2.update(extraction_completed_at: Time.current)

      result = activity.send(:all_records_extracted?, sync_run.sync_read_records)
      expect(result).to be true
    end
  end
end
