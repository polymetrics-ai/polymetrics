# frozen_string_literal: true

class SyncWriteRecord < ApplicationRecord
  belongs_to :sync_run

  validates :data, presence: true
  validates :signature, presence: true, uniqueness: { scope: :sync_run_id }
  validates :status, presence: true

  before_validation :generate_signature, on: :create

  enum status: { pending: 0, written: 1, failed: 2 }

  private

  def generate_signature
    self.signature = Digest::SHA256.hexdigest(data.to_json)
  end
end
