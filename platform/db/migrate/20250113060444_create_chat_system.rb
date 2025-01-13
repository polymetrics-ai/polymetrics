# frozen_string_literal: true

class CreateChatSystem < ActiveRecord::Migration[7.1]
  def change
    create_chats
    create_messages
    create_pipelines
    create_pipeline_actions
  end

  private

  def create_chats
    create_table :chats do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :status, default: 0, null: false
      t.timestamps

      t.index %i[workspace_id user_id]
    end
  end

  def create_messages
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :role, null: false
      t.integer :message_type, null: false
      t.boolean :answered, null: false, default: false
      t.timestamps
    end
  end

  def create_pipelines
    create_table :pipelines do |t|
      t.references :message, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.timestamps
    end
  end

  def create_pipeline_actions
    create_table :pipeline_actions do |t|
      t.references :pipeline, null: false, foreign_key: true
      t.references :query_action,
                   foreign_key: { to_table: :pipeline_actions },
                   null: true
      t.integer :action_type, null: false
      t.integer :order, null: false
      t.jsonb :action_data, null: false, default: {}
      t.jsonb :result_data, null: false, default: {}
      t.timestamps

      t.index %i[pipeline_id order], unique: true
    end
  end
end
