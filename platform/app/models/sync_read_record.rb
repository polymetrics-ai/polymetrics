# frozen_string_literal: true

class SyncReadRecord < ApplicationRecord
  belongs_to :sync_run
  belongs_to :sync

  validates :data, presence: true

  before_validation :generate_signature

  private

  # We need to add uniqueness to signature for only particular sync like
  # incremental sync where we don't need duplicates
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
