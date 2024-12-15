# frozen_string_literal: true

# spec/models/sync_spec.rb
require "rails_helper"

RSpec.describe Sync, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:connection) }
    it { is_expected.to have_many(:sync_runs).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:sync) }

    it { is_expected.to validate_presence_of(:stream_name) }
    it { is_expected.to validate_uniqueness_of(:stream_name).scoped_to(:connection_id) }
    it { is_expected.to validate_length_of(:stream_name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:sync_mode) }
    it { is_expected.to validate_presence_of(:schedule_type) }
  end

  describe "enums" do
    subject(:sync) { described_class.new }

    it {
      expect(sync).to define_enum_for(:status).with_values(synced: 0, syncing: 1, queued: 2, error: 3,
                                                           action_required: 4)
    }

    it {
      expect(sync).to define_enum_for(:sync_mode).with_values(
        full_refresh_overwrite: 0,
        full_refresh_append: 1,
        incremental_append: 2,
        incremental_dedup_history: 3,
        incremental_dedup: 4
      )
    }

    it { is_expected.to define_enum_for(:schedule_type).with_values(scheduled: 0, cron: 1, manual: 2) }
  end

  describe "conditional validations" do
    context "when schedule_type is not manual" do
      it "validates presence of sync_frequency" do
        sync = build(:sync, schedule_type: :scheduled, sync_frequency: nil)
        expect(sync).to be_invalid
        expect(sync.errors[:sync_frequency]).to include("can't be blank")
      end
    end

    context "when schedule_type is manual" do
      it "does not validate presence of sync_frequency" do
        sync = build(:sync, :manual)
        expect(sync).to be_valid
      end
    end
  end

  describe "#supports_incremental?" do
    it "returns true when supported_sync_modes includes 'incremental'" do
      sync = build(:sync, supported_sync_modes: %w[full_refresh incremental])
      expect(sync.supports_incremental?).to be true
    end

    it "returns false when supported_sync_modes does not include 'incremental'" do
      sync = build(:sync, supported_sync_modes: ["full_refresh"])
      expect(sync.supports_incremental?).to be false
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:sync)).to be_valid
    end

    it "is valid with manual schedule type and no sync frequency" do
      expect(build(:sync, :manual)).to be_valid
    end

    it "creates syncs with different statuses" do
      aggregate_failures do
        synced_sync = create(:sync, status: :synced)
        syncing_sync = create(:sync, status: :syncing)
        queued_sync = create(:sync, status: :queued)
        error_sync = create(:sync, status: :error)

        expect(synced_sync.status).to eq("synced")
        expect(syncing_sync.status).to eq("syncing")
        expect(queued_sync.status).to eq("queued")
        expect(error_sync.status).to eq("error")
      end
    end
  end
end
