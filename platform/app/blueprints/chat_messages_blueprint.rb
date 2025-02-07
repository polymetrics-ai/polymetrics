# frozen_string_literal: true

class ChatMessagesBlueprint < Blueprinter::Base
  identifier :id

  fields :content, :role, :message_type, :created_at

  field :content do |message|
    ChatBlueprint.parse_content(message)
  end

  field :pipeline_data do |message|
    next unless message.pipeline.present? && message.message_type == "pipeline"

    {
      id: message.pipeline.id,
      status: message.pipeline.status,
      actions: message.pipeline.pipeline_actions.map do |action|
        base_action = {
          id: action.id,
          action_type: action.action_type,
          position: action.position,
          created_at: action.created_at
        }

        case action.action_type.to_sym
        when :connector_selection
          base_action.merge(
            data: connector_selection_data(action, message)
          )
        when :connection_creation
          base_action.merge(
            data: connection_creation_data(action, message)
          )
        when :sync_initialization
          base_action.merge(
            data: sync_initialization_data(action, message)
          )
        when :query_generation
          base_action.merge(
            data: {
              # TODO: Add generated query details
              sql: "", # Parse from action_data
              parameters: {}
            }
          )
        when :query_execution
          base_action.merge(
            data: {
              query: action.action_data["query"],
              explanation: action.action_data["explanation"]
            }
          )
        else
          base_action.merge(data: {})
        end
      end
    }
  end

  def self.render_with_data(object, options = {})
    {
      data: JSON.parse(render(object, options))
    }
  end

  def self.connector_selection_data(action, message)
    action_data = begin
      action.action_data
    rescue StandardError
      {}
    end
    return {} if action_data.blank?

    connector_ids = extract_connector_ids(action_data)
    connectors = fetch_ordered_connectors(message.chat.workspace, connector_ids)

    {
      connectors: map_connectors_with_display_names(connectors, action_data, connector_ids)
    }
  end

  def self.extract_connector_ids(action_data)
    [
      action_data.dig("source", "connector_id")&.to_i,
      action_data.dig("destination", "connector_id")&.to_i
    ].compact
  end

  def self.fetch_ordered_connectors(workspace, connector_ids)
    return [] if connector_ids.empty?

    workspace.connectors
             .where(id: connector_ids)
             .index_by(&:id)
             .values_at(*connector_ids)
             .compact
  end

  def self.map_connectors_with_display_names(connectors, _action_data, _original_ids)
    connectors.map do |connector|
      {
        id: connector.id,
        name: connector.connector_class_name.capitalize,
        icon_url: connector.icon_url,
        display_name: connector.name
      }
    end
  end

  def self.connection_creation_data(action, message)
    action_data = begin
      action.action_data
    rescue StandardError
      {}
    end
    return {} if action_data.blank?

    connection = message.chat.workspace.connections.find_by(id: action_data["connection_id"])
    return {} unless connection

    {
      connection_id: connection.id,
      streams: action_data["streams"] || [],
      created_at: action_data["created_at"],
      source: {
        name: connection.source.name,
        icon_url: connection.source.icon_url
      },
      destination: {
        name: connection.destination.name,
        icon_url: connection.destination.icon_url
      }
    }
  end

  def self.sync_initialization_data(action, message)
    action_data = begin
      action.action_data
    rescue StandardError
      {}
    end
    return {} if action_data.blank?

    connection = message.chat.workspace.connections.find_by(id: action_data["connection_id"])
    return {} unless connection

    {
      connection_id: connection.id,
      workflow_run_id: action_data["connection_workflow_run_id"],
      syncs: connection.syncs.map do |sync|
        last_run = sync.sync_runs.last
        {
          status: sync.status,
          stream_name: sync.stream_name,
          last_synced_at: last_run&.completed_at
        }
      end
    }
  end
end
