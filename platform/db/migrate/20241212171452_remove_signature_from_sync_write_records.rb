class RemoveSignatureFromSyncWriteRecords < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # First remove the index safely
    remove_index :sync_write_records, 
                column: :signature, 
                algorithm: :concurrently, 
                if_exists: true

    # Then remove the column safely
    safety_assured { 
      remove_column :sync_write_records, :signature 
    }
  end

  def down
    # Add the column back
    add_column :sync_write_records, :signature, :string

    # Add the index back safely
    add_index :sync_write_records, 
             :signature, 
             algorithm: :concurrently, 
             if_exists: false
  end
end
