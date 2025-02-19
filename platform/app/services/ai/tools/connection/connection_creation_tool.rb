# frozen_string_literal: true

module Ai
  module Tools
    module Connection
      class ConnectionCreationTool < BaseTool
        define_function(
          :create_connection,
          description: "Creates a new connection for query based on the selected connector and streams"
        ) do
          property :query,
                   type: "string",
                   description: "User query and requirements",
                   required: true
        end

        def initialize(workspace_id:, chat_id:)
          @workspace_id = workspace_id
          @chat_id = chat_id
          @chat = Chat.find(@chat_id)
        end

        def create_connection(query:)
          @query = query
          connection_params = extract_connection_params
          selected_streams = extract_selected_streams(connection_params)

          create_or_use_existing_connection(connection_params, selected_streams)
        rescue StandardError => e
          handle_connection_error(e, selected_streams)
        end

        private

        def extract_connection_params
          pipeline_message = @chat.messages.where(message_type: "pipeline").last
          return {} if pipeline_message.blank?

          JSON.parse(pipeline_message.content)
        end

        def extract_selected_streams(connection_params)
          connection_params["source"]["streams"].pluck("name")
        end

        def create_or_use_existing_connection(connection_params, selected_streams)
          @connection_id = ::CreateConnectionAndSyncsService.new(
            connection_params["source"]["connector_id"],
            selected_streams
          ).call

          connection = ::Connection.find(@connection_id)

          add_connection_to_chat(connection)
          build_success_response(connection, selected_streams)
        rescue ActiveRecord::RecordInvalid => e
          handle_existing_connection(e, selected_streams)
        end

        def add_connection_to_chat(connection)
          @chat.connections << connection
        end

        def build_success_response(connection, selected_streams)
          {
            success: true,
            message: success_message(connection, selected_streams),
            connection_id: connection.id
          }
        end

        def success_message(_connection, selected_streams)
          if @connection_id.present?
            "Successfully created connection with #{selected_streams.length} streams: #{selected_streams.join(", ")}"
          else
            "Using existing connection with #{selected_streams.length} streams: #{selected_streams.join(", ")}"
          end
        end

        def handle_existing_connection(error, selected_streams)
          if error.message.include?("Name has already been taken")
            existing_connection = find_existing_connection(error.record)
            add_connection_to_chat(existing_connection)
            build_success_response(existing_connection, selected_streams)
          else
            handle_error(error.message)
          end
        end

        def find_existing_connection(record)
          ::Connection.find_by(
            name: record.name,
            workspace_id: @workspace_id
          )
        end

        def handle_connection_error(error, selected_streams)
          if error.is_a?(ActiveRecord::RecordInvalid)
            handle_existing_connection(error, selected_streams)
          else
            handle_error(error.message)
          end
        end

        def find_and_validate_connector(connector_id)
          ::Connector.find_by(
            id: connector_id,
            workspace_id: workspace_id
          )
        end
      end
    end
  end
end
