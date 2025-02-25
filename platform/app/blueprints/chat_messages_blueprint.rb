# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
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
      actions: message.pipeline.pipeline_actions.map { |action| process_pipeline_action(action, message) }
    }
  end

  def self.render_with_data(object, options = {})
    {
      data: JSON.parse(render(object, options))
    }
  end

  private_class_method def self.process_pipeline_action(action, message)
    base_action = action_base_data(action)
    action_handler = ACTION_HANDLERS[action.action_type.to_sym] || :handle_default_action

    send(action_handler, action, message, base_action)
  end

  def self.action_base_data(action)
    {
      id: action.id,
      action_type: action.action_type,
      position: action.position,
      created_at: action.created_at
    }
  end

  ACTION_HANDLERS = {
    connector_selection: :handle_connector_selection,
    connection_creation: :handle_connection_creation,
    sync_initialization: :handle_sync_initialization,
    query_execution: :handle_query_execution,
    query_generation: :handle_query_generation
  }.freeze

  def self.handle_connector_selection(action, message, base_action)
    base_action.merge(
      data: connector_selection_data(action.action_data, message)
    )
  end

  def self.handle_connection_creation(action, message, base_action)
    base_action.merge(
      data: action.action_data.map { |data| connection_creation_data(data, message) }
    )
  end

  def self.handle_sync_initialization(action, message, base_action)
    base_action.merge(
      data: sync_initialization_data(action, message)
    )
  end

  def self.handle_query_execution(action, _message, base_action)
    base_action.merge(
      data: {
        query_data: action.action_data["query_data"]["data"],
        limit: action.action_data["query_data"]["limit"],
        total_records: action.action_data["query_data"]["total_records"]
      }
    )
  end

  def self.handle_query_generation(action, _message, base_action)
    base_action.merge(
      data: {
        query: action.action_data["query"],
        explanation: action.action_data["explanation"]
      }
    )
  end

  def self.handle_default_action(_action, _message, base_action)
    base_action.merge(data: {})
  end

  # rubocop:disable Metrics/AbcSize
  def self.connector_selection_data(action_data, message)
    # Collect all connector IDs from all action data entries
    connector_ids = action_data.flat_map do |data|
      [
        data.dig("source", "connector_id")&.to_i,
        data.dig("destination", "connector_id")&.to_i
      ].compact
    end.uniq

    connectors = fetch_ordered_connectors(message.chat.workspace, connector_ids)

    {
      connectors: connectors.map { |c| map_connector(c) },
      streams: action_data.flat_map { |d| d.dig("source", "streams") }.compact.uniq
    }
  end
  # rubocop:enable Metrics/AbcSize

  def self.connection_creation_data(action_data, message)
    connection = message.chat.connections.find_by(id: action_data["connection_id"])
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

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
  def self.sync_initialization_data(action, message)
    connections = message.chat.connections
    return {} unless connections.any?

    action_data = action.action_data["connections"] || []

    connections.map do |connection|
      connection_data = action_data.find { |c| c["connection_id"] == connection.id.to_s }

      {
        connection_id: connection.id,
        workflow_run_id: connection_data&.dig("connection_workflow_run_id"),
        syncs: connection.syncs.map do |sync|
          last_run = sync.sync_runs.last
          {
            status: sync.status,
            stream_name: sync.stream_name,
            last_synced_at: last_run&.completed_at,
            connection_name: connection.name
          }
        end
      }
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

  def self.fetch_ordered_connectors(workspace, connector_ids)
    return [] if connector_ids.empty?

    workspace.connectors
             .where(id: connector_ids)
             .index_by(&:id)
             .values_at(*connector_ids)
             .compact
  end

  def self.map_connector(connector)
    {
      id: connector.id,
      name: connector.connector_class_name.capitalize,
      icon_url: connector.icon_url,
      display_name: connector.name
    }
  end
end
# rubocop:enable Metrics/ClassLength
