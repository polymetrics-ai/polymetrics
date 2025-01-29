# frozen_string_literal: true

module Api
  module V1
    module Agents
      class DataAgentController < ApplicationController
        def chat
          result = initialize_chat_service.call
          render_chat_success(result)
        rescue StandardError => e
          render_chat_error(e)
        end

        private

        def initialize_chat_service
          ChatAgent::InitializationService.new(
            workspace_id: current_workspace.id,
            user_id: current_user.id,
            query: chat_params[:query],
            title: chat_params[:title]
          )
        end

        def render_chat_success(result)
          render json: {
            status: :success,
            data: {
              chat_id: result[:chat].id,
              workflow_id: result[:workflow_id]
            }
          }
        end

        def render_chat_error(exception)
          render json: {
            status: :error,
            error: exception.message
          }, status: :unprocessable_entity
        end

        def chat_params
          params.require(:chat).permit(:query, :title)
        end
      end
    end
  end
end
