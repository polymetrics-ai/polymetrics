# frozen_string_literal: true

class SyncRun < ApplicationRecord
  belongs_to :sync
  has_many :sync_logs, dependent: :destroy

  enum status: { running: 0, succeeded: 1, failed: 2 }

  validates :status, presence: true
  validates :started_at, presence: true
  validates :ended_at, presence: true
end
