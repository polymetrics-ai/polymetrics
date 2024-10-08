# frozen_string_literal: true

class SyncWriteRecord < ApplicationRecord
  belongs_to :sync_run
  belongs_to :sync

  validates :data, presence: true
  validates :status, presence: true

  enum status: { pending: 0, written: 1, failed: 2 }

  before_validation :generate_signature

  private

  def generate_signature
    self.signature = Digest::SHA256.hexdigest(normalized_data) if data.present?
  end

  def sorted_data
    case data.class.name
    when "Hash"
      data.deep_sort!.to_json
    when "Array"
      data.deep_sort_by(&:to_s).to_json
    else
      data.to_json
    end
  end

  def normalized_data
    "#{sorted_data}-#{sync_id}"
  end
end
