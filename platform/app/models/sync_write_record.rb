# frozen_string_literal: true

class SyncWriteRecord < ApplicationRecord
  belongs_to :sync_run
  belongs_to :sync
  belongs_to :sync_read_record

  validates :data, presence: true
  validates :destination_action, presence: true

  enum destination_action: {
    create: 0,
    insert: 1,
    update: 2,
    delete: 3
  }, _prefix: "destination_action"

  enum status: { pending: 0, written: 1, failed: 2 }
end
