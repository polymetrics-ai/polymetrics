# frozen_string_literal: true

class PipelineAction < ApplicationRecord
  belongs_to :pipeline
  belongs_to :query_action, class_name: "PipelineAction", optional: true

  validates :action_type, presence: true
  validates :order, presence: true, numericality: { only_integer: true }
  validates :action_data, presence: true
  validate :validate_action_data_schema, if: :action_type
  validate :validate_query_action_reference, if: :summary_generation?

  enum action_type: {
    connection_creation: 0,
    query_execution: 1,
    summary_generation: 2
  }

  store_accessor :result_data, :execution_status, :error_message, :output

  private

  def validate_action_data_schema
    case action_type.to_sym
    when :connection_creation
      validate_connection_creation_schema
    when :query_execution
      validate_query_execution_schema
    when :summary_generation
      validate_summary_generation_schema
    end
  end

  def validate_query_action_reference
    return unless summary_generation? && query_action_id.nil?

    errors.add(:query_action_id, "must be present for summary generation actions")
  end

  def validate_connection_creation_schema
    required_keys = %w[source_connector_id streams]
    validate_required_keys(required_keys)
  end

  def validate_query_execution_schema
    required_keys = %w[query connection_id]
    validate_required_keys(required_keys)
  end

  def validate_summary_generation_schema
    required_keys = ["summary_description"]
    validate_required_keys(required_keys)
  end

  def validate_required_keys(required_keys)
    return unless action_data.is_a?(Hash)

    missing_keys = required_keys - action_data.keys
    return unless missing_keys.any?

    errors.add(:action_data, "missing required keys: #{missing_keys.join(", ")}")
  end
end
