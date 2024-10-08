# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncRun, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:sync) }
    it { is_expected.to have_many(:sync_logs).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:started_at) }

    %i[total_records_read total_records_written
       successful_records_read failed_records_read
       successful_records_write records_failed_to_write].each do |attribute|
      it { is_expected.to validate_presence_of(attribute) }
      it { is_expected.to validate_numericality_of(attribute).is_greater_than_or_equal_to(0) }
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(running: 0, succeeded: 1, failed: 2) }
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:sync_run)).to be_valid
    end

    it "is valid with succeeded status" do
      expect(build(:sync_run, :succeeded)).to be_valid
    end

    it "is valid with failed status" do
      expect(build(:sync_run, :failed)).to be_valid
    end
  end

  describe "default values" do
    let(:sync_run) { create(:sync_run) }

    it "sets default values for counters" do
      expect(sync_run.total_records_read).to eq(0)
      expect(sync_run.total_records_written).to eq(0)
      expect(sync_run.successful_records_read).to eq(0)
      expect(sync_run.failed_records_read).to eq(0)
      expect(sync_run.successful_records_write).to eq(0)
      expect(sync_run.records_failed_to_write).to eq(0)
    end
  end

  describe "status transitions" do
    let(:sync_run) { create(:sync_run) }

    it "can transition from running to succeeded" do
      expect(sync_run.status).to eq("running")
      sync_run.succeeded!
      expect(sync_run.status).to eq("succeeded")
    end

    it "can transition from running to failed" do
      expect(sync_run.status).to eq("running")
      sync_run.failed!
      expect(sync_run.status).to eq("failed")
    end
  end
end
