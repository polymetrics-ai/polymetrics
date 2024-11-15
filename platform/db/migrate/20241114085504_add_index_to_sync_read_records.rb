class AddIndexToSyncReadRecords < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :sync_read_records, [:signature, :sync_id], unique: true, algorithm: :concurrently
  end
end
