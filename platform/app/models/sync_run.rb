# frozen_string_literal: true

class SyncRun < ApplicationRecord
  belongs_to :sync
  has_many :sync_logs, dependent: :destroy

  enum status: { running: 0, succeeded: 1, failed: 2 }

  validates :status, presence: true
  validates :started_at, presence: true
  validates :total_records_read, :total_records_written,
            :successful_records_read, :failed_records_read,
            :successful_records_write, :records_failed_to_write,
            presence: true, numericality: { greater_than_or_equal_to: 0 }
end
