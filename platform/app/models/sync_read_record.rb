# frozen_string_literal: true

class SyncReadRecord < ApplicationRecord
  belongs_to :sync_run
  belongs_to :sync

  validates :data, presence: true
  validates :signature, presence: true, uniqueness: { scope: :sync_id }

  before_validation :generate_signature

  private

  def generate_signature
    self.signature = Digest::SHA256.hexdigest(normalized_data.to_json)
  end

  def sorted_data
    case data
    when Hash
      data.deep_sort.to_json
    when Array
      data.deep_sort_by(&:to_s).to_json
    else
      data.to_json
    end
  end

  def normalized_data
    "#{sorted_data}-#{sync_id}"
  end
end
