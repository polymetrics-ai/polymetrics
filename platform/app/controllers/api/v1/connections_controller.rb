# frozen_string_literal: true

module Api
  module V1
    class ConnectionsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_connection, only: %i[start_sync stop_sync]

      def index
        connections = fetch_workspace_connections
        render_connections_response(connections)
      end

      def start_sync
        Connections::StartDataSyncService.new(@connection).call
        render_sync_status_response("started")
      rescue StandardError => e
        @connection.fail!
        render_error(e.message)
      end

      def stop_sync
        # SyncManager.stop(@connection)
        render_sync_status_response("stopped")
      end

      private

      def set_connection
        @connection = current_workspace.connections.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Connection with ID #{params[:id]} not found in workspace #{current_workspace&.id}")
      end

      def fetch_workspace_connections
        current_workspace
          .connections
          .includes(:source, :destination, :syncs)
      end

      def render_connections_response(connections)
        render_api_response(
          ConnectionBlueprint.render_as_hash(connections),
          :ok
        )
      end

      def render_sync_status_response(status)
        render_api_response(
          { message: "Sync #{status} successfully" },
          :ok
        )
      end
    end
  end
end
