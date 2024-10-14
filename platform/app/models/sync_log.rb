# frozen_string_literal: true

class SyncLog < ApplicationRecord
  belongs_to :sync_run

  # Enum for categorizing log entries by severity level
  enum log_type: { info: 0, warn: 1, error: 2, debug: 3 }

  validates :log_type, presence: true
  validates :emitted_at, presence: true

  def self.chronological
    order(emitted_at: :desc)
  end

  scope :errors, -> { where(log_type: :error) }
  scope :warnings, -> { where(log_type: :warn) }
  scope :infos, -> { where(log_type: :info) }
  scope :debugs, -> { where(log_type: :debug) }
end
