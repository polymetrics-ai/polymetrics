# frozen_string_literal: true

class AddTemporalIdsToSyncRuns < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    change_table :sync_runs, bulk: true do |t|
      t.string :temporal_workflow_id
      t.string :temporal_run_id
      t.jsonb :temporal_read_data_workflow_ids, default: []
    end

    add_index :sync_runs, :temporal_read_data_workflow_ids, using: :gin, algorithm: :concurrently
    add_index :sync_runs, :temporal_workflow_id, algorithm: :concurrently
    add_index :sync_runs, :temporal_run_id, algorithm: :concurrently
  end
end
