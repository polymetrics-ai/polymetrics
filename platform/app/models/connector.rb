# frozen_string_literal: true

class Connector < ApplicationRecord
  belongs_to :workspace

  enum connector_language: { ruby: 0, python: 1, javascript: 2 }

  validates :connector_class_name, presence: true
  validates :name, presence: true
  validates :connector_language, presence: true
  validates :name, uniqueness: {
    scope: %i[workspace_id configuration],
    message: lambda do |_object, data|
      "#{data[:value]} already exists for this workspace with the same configuration. " \
        "Please change the name or configuration."
    end
  }

  def icon_url
    @icon_url ||= "https://raw.githubusercontent.com/polymetrics-ai/polymetrics/main/public/connector_icons/#{connector_class_name}.svg"
  end
end
