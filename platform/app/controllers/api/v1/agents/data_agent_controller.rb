# frozen_string_literal: true

module Api
  module V1
    module Agents
      class DataAgentController < ApplicationController
        before_action :authenticate_user!

        def chat
          result = initialize_chat_service.call
          render json: ChatBlueprint.render_with_data(result[:chat], view: :chat, workflow_id: result[:workflow_id])
        rescue StandardError => e
          render_chat_error(e)
        end

        def history
          chats = current_workspace.chats
                                   .includes(:messages)
                                   .where(user: current_user)
                                   .order(created_at: :desc)

          render json: ChatBlueprint.render_with_data(chats, view: :history)
        end

        def chat_messages
          chat = current_workspace.chats
                                  .where(user: current_user)
                                  .find(params[:chat_id])

          render json: ChatMessagesBlueprint.render_with_data(chat.messages.order(created_at: :asc))
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Chat not found" }, status: :not_found
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

        def render_chat_error(exception)
          render json: {
            status: :error,
            error: exception.message
          }, status: :unprocessable_entity
        end

        def chat_params
          params.require(:chat).permit(:query, :title, :chat_id)
        end
      end
    end
  end
end
