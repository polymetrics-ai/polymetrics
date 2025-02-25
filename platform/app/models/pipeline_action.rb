# frozen_string_literal: true

class PipelineAction < ApplicationRecord
  belongs_to :pipeline
  belongs_to :query_action, class_name: "PipelineAction", optional: true

  validates :action_type, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
  validates :action_data, presence: true
  validate :validate_action_data_schema, if: :action_type

  enum action_type: {
    connector_selection: 0,
    connection_creation: 1,
    sync_initialization: 2,
    query_generation: 3,
    query_execution: 4
  }

  store_accessor :result_data, :execution_status, :error_message, :output

  private

  def validate_action_data_schema
    return unless action_data.is_a?(Hash)

    case action_type.to_sym
    when :connector_selection
      validate_connector_selection_schema
    when :connection_creation
      validate_connection_creation_schema
    when :sync_initialization
      validate_sync_initialization_schema
    when :query_execution
      validate_query_execution_schema
    when :query_generation
      validate_query_generation_schema
    end
  end

  def validate_connector_selection_schema
    required_keys = [
      "source/connector_id",
      "destination/connector_id"
    ]
    validate_nested_required_keys(required_keys)
  end

  def validate_connection_creation_schema
    required_keys = %w[streams created_at connection_id]
    validate_required_keys(required_keys)
  end

  def validate_sync_initialization_schema
    required_keys = %w[connections]
    validate_required_keys(required_keys)
  end

  def validate_query_generation_schema
    required_keys = %w[query]
    optional_keys = %w[warnings explanation]
    validate_required_keys(required_keys)
    validate_allowed_keys(required_keys + optional_keys)
  end

  def validate_query_execution_schema
    required_keys = ["query_data"]
    validate_required_keys(required_keys)
  end

  def validate_nested_required_keys(keys)
    keys.each do |key|
      path = key.split("/")
      value = action_data.dig(*path)
      errors.add(:action_data, "missing required key: #{key}") if value.blank?
    end
  end

  def validate_required_keys(required_keys)
    return unless action_data.is_a?(Hash)

    missing_keys = required_keys.select { |k| action_data[k].blank? }
    return if missing_keys.empty?

    errors.add(:action_data, "missing required keys: #{missing_keys.join(", ")}")
  end

  def validate_allowed_keys(allowed_keys)
    invalid_keys = action_data.keys - allowed_keys
    return if invalid_keys.empty?

    errors.add(:action_data, "invalid keys: #{invalid_keys.join(", ")}")
  end
end
