# frozen_string_literal: true

class ConnectionBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :status, :schedule_type, :sync_frequency,
         :namespace, :stream_prefix, :configuration,
         :created_at, :updated_at

  association :source, blueprint: ConnectorBlueprint
  association :destination, blueprint: ConnectorBlueprint
  association :syncs, blueprint: SyncBlueprint
end
