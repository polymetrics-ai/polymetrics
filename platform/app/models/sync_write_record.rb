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
  }, _prefix: 'destination_action'

  enum status: { pending: 0, written: 1, failed: 2 }

  before_validation :generate_signatures

  private

  def generate_signatures
    if data.present?
      self.data_signature = generate_data_signature
      self.primary_key_signature = generate_primary_key_signature
    end
  end

  def generate_data_signature
    Digest::SHA256.hexdigest(normalized_data)
  end

  def generate_primary_key_signature
    return nil unless primary_key_data.present?
    
    Digest::SHA256.hexdigest("#{primary_key_data}-#{sync_id}")
  end

  def primary_key_data
    return nil unless sync.source_defined_primary_key.present? && data.present?
    
    primary_keys = sync.source_defined_primary_key
    primary_key_values = primary_keys.map { |key| data[key] }
    
    primary_key_values.compact.sort.join('-')
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
