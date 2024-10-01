# frozen_string_literal: true

class SyncReadRecord < ApplicationRecord
  belongs_to :sync_run

  validates :data, presence: true
  validates :signature, presence: true, uniqueness: { scope: :sync_run_id }

  before_validation :generate_signature, on: :create

  private

  def generate_signature
    self.signature = Digest::SHA256.hexdigest(data.to_json)
  end
end
