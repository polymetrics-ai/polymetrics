# frozen_string_literal: true

class CreateChatConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_connections do |t|
      t.references :chat, null: false, foreign_key: true
      t.references :connection, null: false, foreign_key: true
      t.timestamps
    end

    add_index :chat_connections, %i[chat_id connection_id], unique: true
  end
end
