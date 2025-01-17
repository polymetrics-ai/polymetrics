# frozen_string_literal: true

class SyncRun < ApplicationRecord
  belongs_to :sync
  has_many :sync_logs, dependent: :destroy
  has_many :sync_read_records, dependent: :destroy
  has_many :sync_write_records, dependent: :destroy

  enum status: { running: 0, succeeded: 1, failed: 2, cancelled: 3 }

  validates :status, presence: true
  validates :started_at, presence: true
  validates :total_records_read, :total_records_written,
            :successful_records_read, :failed_records_read,
            :successful_records_write, :records_failed_to_write,
            presence: true, numericality: { greater_than_or_equal_to: 0 }

  validate :total_pages_greater_than_or_equal_to_current_page, if: -> { total_pages.present? }

  before_validation :set_started_at, on: :create
  before_save :update_completed_at, if: :status_changed?

  def self.chronological
    order(started_at: :desc)
  end

  validate :completed_at_after_started_at, if: -> { started_at.present? && completed_at.present? }

  def extraction_completed?
    extraction_completed
  end

  def extraction_progress
    return 0 if total_records_read.zero?

    (successful_records_read.to_f / total_records_read * 100).round(2)
  end

  def add_read_data_workflow(workflow_id, run_id)
    raise ArgumentError, "workflow_id cannot be nil" if workflow_id.nil?
    raise ArgumentError, "run_id cannot be nil" if run_id.nil?

    current_workflows = temporal_read_data_workflow_ids || []
    workflow_data = { workflow_id => run_id }

    raise "Workflow ID #{workflow_id} already exists" if current_workflows.any? { |data| data.key?(workflow_id) }

    update!(
      temporal_read_data_workflow_ids: current_workflows + [workflow_data]
    )
  end

  def get_run_id_for_workflow(workflow_id)
    return nil if temporal_read_data_workflow_ids.blank?

    workflow_data = temporal_read_data_workflow_ids.find { |data| data.key?(workflow_id) }
    workflow_data&.[](workflow_id)
  end

  private

  def total_pages_greater_than_or_equal_to_current_page
    return unless total_pages && current_page
    return if total_pages >= current_page

    errors.add(:total_pages, "must be greater than or equal to current page")
  end

  def completed_at_after_started_at
    return if started_at < completed_at

    errors.add(:completed_at, "must be after started_at")
  end

  def set_started_at
    self.started_at ||= Time.current
  end

  def update_completed_at
    self.completed_at = Time.current if succeeded? || failed?
  end
end
