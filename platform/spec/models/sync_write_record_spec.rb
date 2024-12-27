# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncWriteRecord, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:sync_run) }
    it { is_expected.to belong_to(:sync) }
    it { is_expected.to belong_to(:sync_read_record) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:data) }
    it { is_expected.to validate_presence_of(:destination_action) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, written: 1, failed: 2) }

    it do
      expect(subject).to define_enum_for(:destination_action)
        .with_values(create: 0, insert: 1, update: 2, delete: 3)
        .with_prefix("destination_action")
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
  end

  describe "scopes" do
    let!(:pending_record) { create(:sync_write_record, status: :pending) }
    let!(:written_record) { create(:sync_write_record, status: :written) }
    let!(:failed_record) { create(:sync_write_record, status: :failed) }

    it "has a scope for pending records" do
      expect(described_class.pending).to contain_exactly(pending_record)
    end

    it "has a scope for written records" do
      expect(described_class.written).to contain_exactly(written_record)
    end

    it "has a scope for failed records" do
      expect(described_class.failed).to contain_exactly(failed_record)
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
end
