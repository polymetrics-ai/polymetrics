# frozen_string_literal: true

class Sync < ApplicationRecord
  belongs_to :connection
  has_many :sync_runs, dependent: :destroy
  has_many :sync_read_records, dependent: :destroy

  enum status: { synced: 0, syncing: 1, queued: 2, error: 3, action_required: 4 }
  enum sync_mode: {
    full_refresh_overwrite: 0,
    full_refresh_append: 1,
    incremental_append: 2,
    incremental_dedup_history: 3,
    incremental_dedup: 4
  }
  enum schedule_type: { scheduled: 0, cron: 1, manual: 2 }

  validates :stream_name, presence: true, uniqueness: { scope: :connection_id }, length: { maximum: 255 }
  validates :status, presence: true
  validates :sync_mode, presence: true
  validates :schedule_type, presence: true
  validates :sync_frequency, presence: true, unless: :manual?

  before_destroy :cleanup_redis_keys

  def supports_incremental?
    supported_sync_modes.include?("incremental")
  end

  private

  def cleanup_redis_keys
    redis = initialize_redis
    delete_bloom_filter_keys(redis)
    delete_run_specific_keys(redis)
    delete_other_sync_keys(redis)

    Rails.logger.info("Cleaned up Redis keys for Sync ##{id}")
  rescue StandardError => e
    Rails.logger.error("Failed to cleanup Redis keys for Sync ##{id}: #{e.message}")
  end

  def delete_bloom_filter_keys(redis)
    bloom_filter_key = "sync:#{id}:signatures:bloom"
    redis.del(bloom_filter_key)
  end

  def delete_run_specific_keys(redis)
    sync_run_keys = redis.keys("sync:#{id}:run:*")
    redis.del(*sync_run_keys) if sync_run_keys.any?
  end

  def delete_other_sync_keys(redis)
    other_sync_keys = redis.keys("sync:#{id}:*")
    redis.del(*other_sync_keys) if other_sync_keys.any?
  end
end
