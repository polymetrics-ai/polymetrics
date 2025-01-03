# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncLog, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:sync_run) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:log_type) }
    it { is_expected.to validate_presence_of(:emitted_at) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:log_type).with_values(info: 0, warn: 1, error: 2, debug: 3) }
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:sync_log)).to be_valid
    end

    it "is valid with warn log type" do
      expect(build(:sync_log, :warn)).to be_valid
    end

    it "is valid with error log type" do
      expect(build(:sync_log, :error)).to be_valid
    end

    it "is valid with debug log type" do
      expect(build(:sync_log, :debug)).to be_valid
    end
  end

  describe "edge cases" do
    it "is valid with a very long message" do
      expect(build(:sync_log, :long_message)).to be_valid
    end

    it "is valid with a future emission time" do
      expect(build(:sync_log, :future_emission)).to be_valid
    end

    it "is valid with a past emission time" do
      expect(build(:sync_log, :past_emission)).to be_valid
    end

    it "is invalid without a sync_run" do
      expect(build(:sync_log, sync_run: nil)).to be_invalid
    end

    it "is invalid with a nil emitted_at" do
      expect(build(:sync_log, emitted_at: nil)).to be_invalid
    end
  end

  describe "scopes" do
    before do
      create(:sync_log, :info)
      create(:sync_log, :warn)
      create(:sync_log, :error)
      create(:sync_log, :debug)
    end

    let(:info_log) { create(:sync_log, log_type: :info) }
    let(:error_log) { create(:sync_log, log_type: :error) }
    let(:warn_log) { create(:sync_log, log_type: :warn) }
    let(:debug_log) { create(:sync_log, log_type: :debug) }

    it "filters by log_type" do
      aggregate_failures do
        expect(SyncLog.where(log_type: :info)).to include(info_log)
        expect(SyncLog.where(log_type: :info)).not_to include(error_log, warn_log, debug_log)
        expect(SyncLog.where(log_type: :error)).to include(error_log)
        expect(SyncLog.where(log_type: :warn)).to include(warn_log)
        expect(SyncLog.where(log_type: :debug)).to include(debug_log)
      end
    end
  end

  describe "ordering" do
    it "orders by emitted_at in descending order by default" do
      old_log = create(:sync_log, emitted_at: 2.days.ago)
      new_log = create(:sync_log, emitted_at: 1.day.ago)
      expect(SyncLog.chronological.first).to eq(new_log)
      expect(SyncLog.chronological.last).to eq(old_log)
    end
  end
end
