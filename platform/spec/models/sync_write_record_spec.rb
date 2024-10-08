# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncWriteRecord, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:sync_run) }
    it { is_expected.to belong_to(:sync) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:data) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, written: 1, failed: 2) }
  end

  describe "callbacks" do
    it "generates a signature before validation" do
      record = build(:sync_write_record, signature: nil)
      expect(record.signature).to be_nil
      record.valid?
      expect(record.signature).not_to be_nil
      expect(record.signature).to be_a(String)
      expect(record.signature.length).to eq(64) # SHA256 hex length
    end
  end

  describe "signature generation" do
    it "generates a consistent signature for the same data within the same sync" do
      data = { "key" => "value" }
      record1 = create(:sync_write_record, data:)
      record2 = create(:sync_write_record, data:, sync: record1.sync)
      expect(record1.signature).to eq(record2.signature)
    end

    it "generates different signatures for the same data with different syncs" do
      data = { "key" => "value" }
      record1 = create(:sync_write_record, data:)
      record2 = create(:sync_write_record, data:)
      expect(record1.signature).not_to eq(record2.signature)
    end

    it "generates the same signature for different data orders within the same sync" do
      record1 = create(:sync_write_record, data: { "a" => 1, "b" => 2 })
      record2 = create(:sync_write_record, data: { "b" => 2, "a" => 1 }, sync: record1.sync)
      expect(record1.signature).to eq(record2.signature)
    end

    it "generates different signatures for arrays with different orders" do
      record1 = create(:sync_write_record, data: [1, 2, 3])
      record2 = create(:sync_write_record, data: [3, 2, 1])
      expect(record1.signature).not_to eq(record2.signature)
    end
  end

  describe "status transitions" do
    it "can transition from pending to written" do
      record = create(:sync_write_record, status: :pending)
      expect(record.pending?).to be true
      record.written!
      expect(record.written?).to be true
    end

    it "can transition from pending to failed" do
      record = create(:sync_write_record, status: :pending)
      expect(record.pending?).to be true
      record.failed!
      expect(record.failed?).to be true
    end

    # implement these when we intoduce state management using AASM
    # it "cannot transition from written to pending" do
    #   record = create(:sync_write_record, status: :written)
    #   expect { record.pending! }.to raise_error(ActiveRecord::RecordInvalid)
    # end

    # implement these when we intoduce state management using AASM
    # it "cannot transition from failed to pending" do
    #   record = create(:sync_write_record, status: :failed)
    #   expect { record.pending! }.to raise_error(ActiveRecord::RecordInvalid)
    # end
  end

  describe "scopes" do
    before do
      create(:sync_write_record, status: :pending)
      create(:sync_write_record, status: :written)
      create(:sync_write_record, status: :failed)
    end

    it "has a scope for pending records" do
      expect(SyncWriteRecord.pending.count).to eq(1)
    end

    it "has a scope for written records" do
      expect(SyncWriteRecord.written.count).to eq(1)
    end

    it "has a scope for failed records" do
      expect(SyncWriteRecord.failed.count).to eq(1)
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:sync_write_record)).to be_valid
    end

    it "is valid with written status" do
      expect(build(:sync_write_record, :written)).to be_valid
    end

    it "is valid with failed status" do
      expect(build(:sync_write_record, :failed)).to be_valid
    end

    it "is valid with complex data" do
      expect(build(:sync_write_record, :complex_data)).to be_valid
    end

    it "is valid with large data" do
      expect(build(:sync_write_record, :large_data)).to be_valid
    end

    it "is invalid with empty data" do
      expect(build(:sync_write_record, :empty_data)).to be_invalid
    end

    it "is valid with null values" do
      expect(build(:sync_write_record, :null_values)).to be_valid
    end

    it "is valid with special characters" do
      expect(build(:sync_write_record, :special_characters)).to be_valid
    end
  end

  describe "edge cases" do
    it "generates different signatures for different data" do
      record1 = create(:sync_write_record, data: { "key" => "value1" })
      record2 = create(:sync_write_record, data: { "key" => "value2" })
      expect(record1.signature).not_to eq(record2.signature)
    end

    it "handles very large data" do
      large_data = { "key" => "a" * 1_000_000 } # 1MB of data
      record = build(:sync_write_record, data: large_data)
      expect(record).to be_valid
    end

    it "is invalid without a sync_run" do
      record = build(:sync_write_record, sync_run: nil)
      expect(record).to be_invalid
      expect(record.errors[:sync_run]).to include("must exist")
    end

    it "is invalid without a sync" do
      record = build(:sync_write_record, sync: nil)
      expect(record).to be_invalid
      expect(record.errors[:sync]).to include("must exist")
    end
  end
end
