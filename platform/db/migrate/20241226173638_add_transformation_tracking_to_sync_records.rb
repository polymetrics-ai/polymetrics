class AddTransformationTrackingToSyncRecords < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :sync_read_records, :transformation_completed_at, :datetime
    add_column :sync_runs, :transformation_completed, :boolean, default: false
    add_column :sync_runs, :last_transformed_at, :datetime
    
    add_index :sync_runs, [:sync_id, :last_transformed_at], algorithm: :concurrently
  end
end
