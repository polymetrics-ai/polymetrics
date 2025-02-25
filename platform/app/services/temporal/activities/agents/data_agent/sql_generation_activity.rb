# frozen_string_literal: true

module Temporal
  module Activities
    module Agents
      module DataAgent
        class SqlGenerationActivity < ::Temporal::Activity
          def execute(chat_id:, query_requirements:)
            chat = Chat.find(chat_id)
            pipeline = chat.messages.find_by(message_type: :pipeline)&.pipeline
            return { status: :skipped } if pipeline.pipeline_actions.exists?(action_type: :query_generation)

            syncs = chat.connections.flat_map(&:syncs)
            destination_schemas = syncs.map(&:destination_database_schema)
            json_schemas = syncs.map(&:schema)

            generated = Ai::SqlGenerationService.new(chat_id: chat_id)
                                                .generate(
                                                  destination_schemas: destination_schemas,
                                                  json_schemas: json_schemas,
                                                  query_requirements: query_requirements
                                                )

            action = create_query_generation_action(pipeline, generated)

            {
              status: :success,
              action_id: action.id,
              query: action.action_data["query"],
              explanation: action.action_data["explanation"]
            }
          rescue StandardError => e
            { status: :error, error: e.message }
          end

          private

          def create_query_generation_action(pipeline, generated_response)
            content = generated_response["content"].find { |c| c["action_type"] == "query_generation" }
            action_data = content["action_data"]

            pipeline.pipeline_actions.create!(
              action_type: :query_generation,
              position: next_position(pipeline),
              action_data: {
                query: action_data["query"],
                explanation: action_data["explanation"],
                warnings: action_data["warnings"] || []
              }
            )
          end

          def next_position(pipeline)
            pipeline.pipeline_actions.maximum(:position).to_i + 1
          end
        end
      end
    end
  end
end
