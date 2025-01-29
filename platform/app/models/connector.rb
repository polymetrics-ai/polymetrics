# frozen_string_literal: true

class Connector < ApplicationRecord
  belongs_to :workspace

  enum connector_language: { ruby: 0, python: 1, javascript: 2 }
  enum integration_type: { database: 0, api: 1 }

  validates :connector_class_name, presence: true
  validates :name, presence: true
  validates :connector_language, presence: true
  validates :integration_type, presence: true
  validates :name, uniqueness: {
    scope: %i[workspace_id configuration],
    message: lambda do |_object, data|
      "#{data[:value]} already exists for this workspace with the same configuration. " \
        "Please change the name or configuration."
    end
  }

  before_save :unset_other_default_analytics_dbs, if: :should_validate_default_analytics_db?
  before_save :ensure_default_analytics_db_is_false_for_api_type, if: :should_validate_default_analytics_db?

  def icon_url
    @icon_url ||= "https://raw.githubusercontent.com/polymetrics-ai/polymetrics/main/public/connector_icons/#{connector_class_name}.svg"
  end

  def fetch_schema
    return [] if integration_type == "database"

    @fetch_schema ||= begin
      Catalogs::FetchSchemaService.new(connector_class_name).call
    rescue StandardError => e
      Rails.logger.error("Error fetching schema for #{connector_class_name}: #{e.message}")
      []
    end
  end

  def available_streams
    fetch_schema.filter_map { |stream_name, _schema| stream_name }
  end

  def stream_descriptions
    fetch_schema.filter_map do |stream_name, schema|
      {
        name: stream_name,
        description: schema["description"],
        sync_modes: schema["x-supported_sync_modes"],
        primary_key: schema["x-source_defined_primary_key"],
        required_fields: schema["required"],
        properties: format_properties(schema["properties"])
      }
    end
  end

  private

  def should_validate_default_analytics_db?
    default_analytics_db_changed?
  end

  def unset_other_default_analytics_dbs
    return unless default_analytics_db

    workspace.connectors.where.not(id: id).find_each do |connector|
      connector.update(default_analytics_db: false)
    end
  end

  def ensure_default_analytics_db_is_false_for_api_type
    return unless api?

    self.default_analytics_db = false
  end

  def format_properties(properties, depth = 0, max_depth = 3)
    return {} if properties.nil? || depth >= max_depth

    properties.transform_values do |property|
      {
        type: property["type"],
        description: property["description"],
        format: property["format"],
        required: property["required"],
        properties: property["type"] == "object" ? format_properties(property["properties"], depth + 1, max_depth) : nil
      }.compact
    end
  end
end
