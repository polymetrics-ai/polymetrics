# frozen_string_literal: true

module ChatAgent
  class InitializationService
    def initialize(workspace_id:, user_id:, query:, title:)
      @workspace_id = workspace_id
      @user_id = user_id
      @query = query
      @title = title
    end

    def call
      ActiveRecord::Base.transaction do
        chat = create_chat
        create_initial_message(chat)
        workflow_id = start_temporal_workflow(chat)

        {
          chat: chat,
          workflow_id: workflow_id
        }
      rescue StandardError => e
        chat&.update(status: :failed)
        raise e
      end
    end

    private

    def create_chat
      Chat.create!(
        workspace_id: @workspace_id,
        user_id: @user_id,
        title: @title || "New Chat",
        status: :active
      )
    end

    def create_initial_message(chat)
      chat.messages.create!(
        content: @query,
        role: :user,
        message_type: :text
      )
    end

    def start_temporal_workflow(chat)
      workflow_id = "chat_#{chat.id}"
      Temporal.start_workflow(
        Temporal::Workflows::Agents::DataAgent::ChatProcessingWorkflow,
        {
          chat_id: chat.id,
          content: @query,
          user_id: @user_id,
          workspace_id: @workspace_id
        },
        options: {
          workflow_id: workflow_id,
          task_queue: "platform_queue"
        }
      )
      workflow_id
    end
  end
end
