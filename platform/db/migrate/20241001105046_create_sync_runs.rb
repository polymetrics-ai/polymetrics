# frozen_string_literal: true

class CreateSyncRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :sync_runs do |t|
      t.references :sync, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.integer :total_records_read, default: 0
      t.integer :total_records_written, default: 0
      t.integer :successful_records_read, default: 0
      t.integer :failed_records_read, default: 0
      t.integer :successful_records_write, default: 0
      t.integer :records_failed_to_write, default: 0

      t.timestamps
    end

    add_index :sync_runs, :status
  end
end
