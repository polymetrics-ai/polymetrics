# frozen_string_literal: true

class ChatBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :status, :created_at, :description

  field :icon_url do |chat|
    # Get the first connection's icon URL from the chat's pipeline
    first_connection = chat.connections.first
    first_connection&.source&.icon_url || "/icon-data-agent.svg"
  end

  field :message_count do |chat|
    chat.messages.size
  end

  field :last_message do |chat|
    last_message = chat.messages.last
    next nil unless last_message

    {
      content: parse_content(last_message),
      role: last_message.role,
      message_type: last_message.message_type,
      created_at: last_message.created_at
    }
  end

  view :history do
    fields :id, :title, :status, :created_at, :description
    field :message_count do |chat|
      chat.messages.size
    end
    field :last_message do |chat|
      last_message = chat.messages.last
      next nil unless last_message

      {
        content: parse_content(last_message),
        role: last_message.role,
        message_type: last_message.message_type,
        created_at: last_message.created_at
      }
    end
  end

  view :chat do
    fields :id, :title, :status, :created_at
    field :workflow_id do |_chat, options|
      options[:workflow_id]
    end
    field :last_message do |chat|
      last_message = chat.messages.last
      next nil unless last_message

      {
        content: parse_content(last_message),
        role: last_message.role,
        message_type: last_message.message_type,
        created_at: last_message.created_at
      }
    end
  end

  def self.render_with_data(object, options = {})
    {
      data: JSON.parse(render(object, options))
    }
  end

  def self.parse_content(message)
    return message.content unless message.message_type == "pipeline"

    begin
      JSON.parse(message.content)
    rescue JSON::ParserError
      message.content
    end
  end
end
