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

  private

  def should_validate_default_analytics_db?
    default_analytics_db_changed?
  end

  def unset_other_default_analytics_dbs
    return unless default_analytics_db

    workspace.connectors.where.not(id:).find_each do |connector|
      connector.update(default_analytics_db: false)
    end
  end

  def ensure_default_analytics_db_is_false_for_api_type
    if api?
      self.default_analytics_db = false
    end
  end
end
