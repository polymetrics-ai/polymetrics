# frozen_string_literal: true

class ConnectorBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :connector_class_name, :connector_language,
         :integration_type, :created_at, :updated_at, :icon_url
end
