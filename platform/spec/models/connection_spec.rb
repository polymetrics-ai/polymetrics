# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connection, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:workspace) }
    it { is_expected.to belong_to(:source).class_name("Connector") }
    it { is_expected.to belong_to(:destination).class_name("Connector") }
    it { is_expected.to have_many(:syncs).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:connection) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:workspace_id) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:schedule_type) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(healthy: 0, failed: 1, running: 2, paused: 3, created: 4) }
    it { is_expected.to define_enum_for(:schedule_type).with_values(scheduled: 0, cron: 1, manual: 2) }
  end

  describe "conditional validations" do
    context "when schedule_type is scheduled" do
      subject { build(:connection, schedule_type: :scheduled) }

      it { is_expected.to validate_presence_of(:sync_frequency) }
    end

    context "when schedule_type is cron" do
      subject { build(:connection, schedule_type: :cron) }

      it { is_expected.to validate_presence_of(:sync_frequency) }
    end

    context "when schedule_type is manual" do
      subject { build(:connection, schedule_type: :manual) }

      it { is_expected.not_to validate_presence_of(:sync_frequency) }
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:connection)).to be_valid
    end

    it "is valid with manual schedule type and no sync frequency" do
      expect(build(:connection, schedule_type: :manual, sync_frequency: nil)).to be_valid
    end
  end

  describe "status transitions" do
    let(:connection) { create(:connection, status: :created) }

    it "starts with created status" do
      expect(connection.status).to eq("created")
    end

    it "can transition to healthy status" do
      connection.healthy!
      expect(connection.status).to eq("healthy")
    end

    it "can transition to failed status" do
      connection.failed!
      expect(connection.status).to eq("failed")
    end

    it "can transition to running status" do
      connection.running!
      expect(connection.status).to eq("running")
    end

    it "can transition to paused status" do
      connection.paused!
      expect(connection.status).to eq("paused")
    end
  end

  describe "edge cases" do
    it "is invalid with a name longer than 255 characters" do
      connection = build(:connection, name: "a" * 256)
      expect(connection).to be_invalid
      expect(connection.errors[:name]).to include("is too long (maximum is 255 characters)")
    end

    it "allows the same name in different workspaces" do
      connection1 = create(:connection)
      connection2 = build(:connection, name: connection1.name, workspace: create(:workspace))
      expect(connection2).to be_valid
    end

    it "handles large JSON configuration" do
      large_config = { "data" => "a" * 1_000_000 } # 1MB of data
      connection = create(:connection, configuration: large_config)
      expect(connection.reload.configuration).to eq(large_config)
    end
  end
end
