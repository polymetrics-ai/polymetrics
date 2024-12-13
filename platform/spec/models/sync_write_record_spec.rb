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
      is_expected.to define_enum_for(:destination_action)
        .with_values(create: 0, insert: 1, update: 2, delete: 3)
        .with_prefix('destination_action')
    end
  end

  describe "callbacks" do
    it "generates signatures before validation" do
      sync = create(:sync, source_defined_primary_key: ["id"])
      record = build(:sync_write_record, 
        sync: sync,
        data: { "id" => "123", "name" => "test" }
      )
      
      expect(record.data_signature).to be_nil
      expect(record.primary_key_signature).to be_nil

      record.valid?

      expect(record.data_signature).to be_present
      expect(record.primary_key_signature).to be_present
    end
  end

  describe "signature generation" do
    let(:sync) { create(:sync, source_defined_primary_key: ["id"]) }
    let(:data) { { "id" => "123", "name" => "test" } }

    describe "#generate_data_signature" do
      it "generates consistent signatures for same data within same sync" do
        record1 = create(:sync_write_record, sync: sync, data: data)
        record2 = create(:sync_write_record, sync: sync, data: data)
        expect(record1.data_signature).to eq(record2.data_signature)
      end

      it "generates different signatures for same data with different syncs" do
        record1 = create(:sync_write_record, data: data)
        record2 = create(:sync_write_record, data: data)
        expect(record1.data_signature).not_to eq(record2.data_signature)
      end

      it "generates same signature for different data orders within same sync" do
        record1 = create(:sync_write_record, sync: sync, data: { "a" => 1, "b" => 2 })
        record2 = create(:sync_write_record, sync: sync, data: { "b" => 2, "a" => 1 })
        expect(record1.data_signature).to eq(record2.data_signature)
      end
    end

    describe "#generate_primary_key_signature" do
      it "generates signature when primary key exists" do
        record = create(:sync_write_record, sync: sync, data: data)
        expect(record.primary_key_signature).to be_present
      end

      it "returns nil when no primary key is defined" do
        sync.update(source_defined_primary_key: [])
        record = create(:sync_write_record, sync: sync, data: data)
        expect(record.primary_key_signature).to be_nil
      end

      it "returns nil when primary key value is missing in data" do
        record = create(:sync_write_record, 
          sync: sync, 
          data: { "name" => "test" }
        )
        expect(record.primary_key_signature).to be_nil
      end

      it "generates consistent signatures for same primary key within same sync" do
        record1 = create(:sync_write_record, sync: sync, data: data)
        record2 = create(:sync_write_record, sync: sync, data: data.merge("name" => "different"))
        expect(record1.primary_key_signature).to eq(record2.primary_key_signature)
      end

      it "handles composite primary keys" do
        sync.update(source_defined_primary_key: ["id", "code"])
        data = { "id" => "123", "code" => "ABC", "name" => "test" }
        record = create(:sync_write_record, sync: sync, data: data)
        expect(record.primary_key_signature).to be_present
      end
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
