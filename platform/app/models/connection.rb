# frozen_string_literal: true

class Connection < ApplicationRecord
  belongs_to :workspace
  belongs_to :source, class_name: "Connector"
  belongs_to :destination, class_name: "Connector"
  has_many :syncs, dependent: :destroy

  enum status: { healthy: 0, failed: 1, running: 2, paused: 3 }
  enum schedule_type: { scheduled: 0, cron: 1, manual: 2 }

  validates :name, presence: true, uniqueness: { scope: :workspace_id }, length: { maximum: 255 }
  validates :status, presence: true
  validates :schedule_type, presence: true
  validates :sync_frequency, presence: true, if: :frequency_required?

  private

  def frequency_required?
    scheduled? || cron?
  end
end
