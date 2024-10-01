# frozen_string_literal: true

class CreateSyncRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :sync_runs do |t|
      t.references :sync, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :started_at, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
