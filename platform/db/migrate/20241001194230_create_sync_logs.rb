# frozen_string_literal: true

class CreateSyncLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :sync_logs do |t|
      t.references :sync_run, null: false, foreign_key: true
      t.integer :log_type, null: false
      t.text :message
      t.datetime :emitted_at, null: false

      t.timestamps
    end

    add_index :sync_logs, :emitted_at
  end
end
