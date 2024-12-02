# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncReadRecord, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:sync_run) }
    it { is_expected.to belong_to(:sync) }
  end

  describe "validations" do
    subject { build(:sync_read_record) }

    context "when validating data" do
      it "validates presence of data" do
        record = build(:sync_read_record, data: nil)
        expect(record).not_to be_valid
        expect(record.errors[:data]).to include("can't be blank")
      end
    end
  end

  describe "callbacks" do
    it "generates a signature before validation on create" do
      aggregate_failures do
        record = build(:sync_read_record, data: { "key" => "value" })
        expect(record.signature).to be_nil

        record.valid?
        expect(record.signature).not_to be_nil
        expect(record.signature).to be_a(String)
        expect(record.signature.length).to be.positive?
      end
    end

    it "changes the signature on update" do
      record = create(:sync_read_record)
      original_signature = record.signature
      record.update(data: { "new_key" => "new_value" })
      expect(record.signature).not_to eq(original_signature)
    end
  end

  describe "signature generation" do
    it "generates a consistent signature for the same data within the same sync_id" do
      data = { "key" => "value" }
      record1 = create(:sync_read_record, data: data)
      record2 = create(:sync_read_record, data: data, sync: record1.sync, sync_run: record1.sync_run)
      expect(record1.signature).to eq(record2.signature)
    end

    it "generates different signatures for the same data with different sync_id" do
      record1 = create(:sync_read_record, data: { "a" => 1, "b" => 2 })
      record2 = create(:sync_read_record, data: { "a" => 1, "b" => 2 })
      expect(record1.signature).not_to eq(record2.signature)
    end

    it "generates the same signature for different data orders within the same sync_id" do
      record1 = create(:sync_read_record, data: { "a" => 1, "b" => 2 })
      record2 = create(:sync_read_record, data: { "b" => 2, "a" => 1 }, sync: record1.sync, sync_run: record1.sync_run)
      expect(record1.signature).to eq(record2.signature)
    end

    it "generates different signatures for arrays with different orders" do
      record1 = create(:sync_read_record, data: [1, 2, 3])
      record2 = create(:sync_read_record, data: [3, 2, 1])
      expect(record1.signature).not_to eq(record2.signature)
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:sync_read_record)).to be_valid
    end

    it "is valid with complex data" do
      expect(build(:sync_read_record, :complex_data)).to be_valid
    end

    it "is valid with large data" do
      expect(build(:sync_read_record, :large_data)).to be_valid
    end

    it "is invalid with empty data" do
      expect(build(:sync_read_record, :empty_data)).to be_invalid
    end

    it "is valid with null values" do
      expect(build(:sync_read_record, :null_values)).to be_valid
    end

    it "is valid with special characters" do
      expect(build(:sync_read_record, :special_characters)).to be_valid
    end
  end

  describe "edge cases" do
    it "generates different signatures for different data" do
      record1 = create(:sync_read_record, data: { "key" => "value1" })
      record2 = create(:sync_read_record, data: { "key" => "value2" })
      expect(record1.signature).not_to eq(record2.signature)
    end

    it "handles very large data" do
      large_data = { "key" => "a" * 1_000_000 } # 1MB of data
      record = build(:sync_read_record, data: large_data)
      expect(record).to be_valid
    end

    it "is invalid without a sync_run" do
      record = build(:sync_read_record, sync_run: nil)
      expect(record).to be_invalid
      expect(record.errors[:sync_run]).to include("must exist")
    end

    it "is invalid without a sync" do
      record = build(:sync_read_record, sync: nil)
      expect(record).to be_invalid
      expect(record.errors[:sync]).to include("must exist")
    end
  end
end
