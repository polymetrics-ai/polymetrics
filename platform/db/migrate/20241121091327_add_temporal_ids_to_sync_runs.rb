class AddTemporalIdsToSyncRuns < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :sync_runs, :temporal_workflow_id, :string
    add_column :sync_runs, :temporal_run_id, :string
    add_column :sync_runs, :temporal_read_data_workflow_ids, :jsonb, default: []
    
    add_index :sync_runs, :temporal_read_data_workflow_ids, using: :gin, algorithm: :concurrently
    add_index :sync_runs, :temporal_workflow_id, algorithm: :concurrently
    add_index :sync_runs, :temporal_run_id, algorithm: :concurrently
  end
end
