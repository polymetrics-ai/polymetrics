# frozen_string_literal: true

module Temporal
  module Activities
    module Agents
      module DataAgent
        class CheckConnectionHealthActivity < ::Temporal::Activity
          # rubocop:disable Metrics/CyclomaticComplexity
          def execute(chat_id:)
            chat = Chat.find(chat_id)
            recently_synced_healthy_connection_ids = []

            chat.connections.each do |connection|
              next unless connection.healthy?

              has_recent_sync = connection.syncs.any? do |sync|
                sync.sync_runs.last&.completed_at&.> 30.minutes.ago
              end

              recently_synced_healthy_connection_ids << connection.id if has_recent_sync
            end

            { recently_synced_healthy_connection_ids: recently_synced_healthy_connection_ids }
          rescue StandardError
            { recently_synced_healthy_connection_ids: [] }
          end
          # rubocop:enable Metrics/CyclomaticComplexity
        end
      end
    end
  end
end
