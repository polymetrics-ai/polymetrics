# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncRun, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:sync) }
    it { is_expected.to have_many(:sync_logs).dependent(:destroy) }
    it { is_expected.to have_many(:sync_read_records).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:status) }

    %i[total_records_read total_records_written
       successful_records_read failed_records_read
       successful_records_write records_failed_to_write].each do |attribute|
      it { is_expected.to validate_presence_of(attribute) }
      it { is_expected.to validate_numericality_of(attribute).is_greater_than_or_equal_to(0) }
    end

    context "when validating total_pages" do
      it "is valid when total_pages is greater than current_page" do
        sync_run = build(:sync_run, total_pages: 5, current_page: 3)
        expect(sync_run).to be_valid
      end

      it "is valid when total_pages equals current_page" do
        sync_run = build(:sync_run, total_pages: 5, current_page: 5)
        expect(sync_run).to be_valid
      end

      it "is invalid when total_pages is less than current_page" do
        sync_run = build(:sync_run, total_pages: 3, current_page: 5)
        expect(sync_run).not_to be_valid
        expect(sync_run.errors[:total_pages]).to include("must be greater than or equal to current page")
      end
    end

    context "when validating timestamps" do
      it "is valid when completed_at is after started_at" do
        sync_run = build(:sync_run, started_at: 1.hour.ago, completed_at: Time.current)
        expect(sync_run).to be_valid
      end

      it "is invalid when completed_at is before started_at" do
        sync_run = build(:sync_run, started_at: 1.hour.ago, completed_at: 2.hours.ago)
        expect(sync_run).not_to be_valid
        expect(sync_run.errors[:completed_at]).to include("must be after started_at")
      end
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(running: 0, succeeded: 1, failed: 2, cancelled: 3) }
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
      aggregate_failures do
        sync_run = SyncRun.new

        expect(sync_run.total_records_read).to eq(0)
        expect(sync_run.total_records_written).to eq(0)
        expect(sync_run.successful_records_read).to eq(0)
        expect(sync_run.failed_records_read).to eq(0)
        expect(sync_run.successful_records_write).to eq(0)
        expect(sync_run.records_failed_to_write).to eq(0)
      end
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

  describe "callbacks" do
    it "sets started_at on create if not provided" do
      sync_run = build(:sync_run, :without_started_at)
      expect(sync_run.started_at).to be_nil
      sync_run.valid? # Trigger the validation
      expect(sync_run.started_at).not_to be_nil
    end

    it "doesn't override started_at if provided" do
      time = 1.hour.ago
      sync_run = build(:sync_run, started_at: time)
      sync_run.save
      expect(sync_run.started_at).to be_within(1.second).of(time)
    end

    it "sets completed_at when transitioning to succeeded" do
      sync_run = create(:sync_run)
      expect { sync_run.succeeded! }.to change(sync_run, :completed_at).from(nil)
    end

    it "sets completed_at when transitioning to failed" do
      sync_run = create(:sync_run)
      expect { sync_run.failed! }.to change(sync_run, :completed_at).from(nil)
    end
  end

  describe "#extraction_completed?" do
    it "returns the extraction_completed value" do
      sync_run = build(:sync_run, extraction_completed: true)
      expect(sync_run.extraction_completed?).to be true
    end
  end

  describe "#extraction_progress" do
    it "returns 0 when total_records_read is zero" do
      sync_run = build(:sync_run, total_records_read: 0, successful_records_read: 0)
      expect(sync_run.extraction_progress).to eq(0)
    end

    it "calculates the correct percentage" do
      sync_run = build(:sync_run, total_records_read: 100, successful_records_read: 75)
      expect(sync_run.extraction_progress).to eq(75.0)
    end
  end

  describe "#add_read_data_workflow" do
    it "adds workflow data to temporal_read_data_workflow_ids" do
      sync_run = create(:sync_run)
      workflow_id = "workflow123"
      run_id = "run456"

      sync_run.add_read_data_workflow(workflow_id, run_id)
      expect(sync_run.temporal_read_data_workflow_ids).to eq([{ workflow_id => run_id }])
    end

    it "preserves existing workflow data" do
      sync_run = create(:sync_run, temporal_read_data_workflow_ids: [{ "existing" => "data" }])
      workflow_id = "workflow123"
      run_id = "run456"

      sync_run.add_read_data_workflow(workflow_id, run_id)
      expect(sync_run.temporal_read_data_workflow_ids).to eq([{ "existing" => "data" }, { workflow_id => run_id }])
    end
  end

  describe "#get_run_id_for_workflow" do
    it "returns nil when temporal_read_data_workflow_ids is blank" do
      sync_run = create(:sync_run, temporal_read_data_workflow_ids: nil)
      expect(sync_run.get_run_id_for_workflow("any")).to be_nil
    end

    it "returns the run_id for a matching workflow_id" do
      workflow_id = "workflow123"
      run_id = "run456"
      sync_run = create(:sync_run, temporal_read_data_workflow_ids: [{ workflow_id => run_id }])

      expect(sync_run.get_run_id_for_workflow(workflow_id)).to eq(run_id)
    end

    it "returns nil for non-matching workflow_id" do
      sync_run = create(:sync_run, temporal_read_data_workflow_ids: [{ "other" => "data" }])
      expect(sync_run.get_run_id_for_workflow("nonexistent")).to be_nil
    end
  end

  describe ".chronological" do
    it "orders sync runs by started_at in descending order" do
      old_run = create(:sync_run, started_at: 2.days.ago)
      new_run = create(:sync_run, started_at: 1.day.ago)

      expect(described_class.chronological).to eq([new_run, old_run])
    end
  end
end
