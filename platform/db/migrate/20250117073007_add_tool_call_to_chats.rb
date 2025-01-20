# frozen_string_literal: true

class AddToolCallToChats < ActiveRecord::Migration[7.1]
  def change
    add_column :chats, :tool_call_data, :jsonb, default: []
  end
end
