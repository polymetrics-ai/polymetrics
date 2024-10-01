# frozen_string_literal: true

class SyncLog < ApplicationRecord
  belongs_to :sync_run

  enum log_type: { info: 0, warn: 1, error: 2, debug: 3 }

  validates :log_type, presence: true
  validates :message, presence: true
  validates :emitted_at, presence: true
end
