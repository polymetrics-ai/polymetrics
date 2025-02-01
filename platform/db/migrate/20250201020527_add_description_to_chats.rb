# frozen_string_literal: true

class AddDescriptionToChats < ActiveRecord::Migration[7.1]
  def change
    add_column :chats, :description, :string, limit: 500
  end
end
