# frozen_string_literal: true

module Api
  module V1
    class ConnectorsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_connector, only: %i[show update destroy]

      def index
        connectors = current_user.workspaces.last.connectors
        render_api_response(connectors, :ok)
      end

      def show
        render_api_response(@connector, :ok)
      end

      def create
        result = Connectors::UpsertService.new(connector_params, current_user).call
        render_api_response(result, :created)
      end

      def update
        result = Connectors::UpsertService.new(connector_params, current_user, @connector).call
        render_api_response(result, :ok)
      end

      def destroy
        @connector.destroy
        head :no_content
      end

      private

      def connector_params
        params.require(:connector).permit(:name, :connector_class_name, :description, :connector_language,
                                          configuration: {})
      end

      def set_connector
        @connector = Connector.find(params[:id])
      end
    end
  end
end
