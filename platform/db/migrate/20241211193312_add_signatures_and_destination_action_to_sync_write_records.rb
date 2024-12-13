# frozen_string_literal: true

class AddSignaturesAndDestinationActionToSyncWriteRecords < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Add columns one by one
    add_column :sync_write_records, :primary_key_signature, :string
    add_column :sync_write_records, :data_signature, :string
    add_column :sync_write_records, :destination_action, :integer, default: 0, null: false

    # Add indexes after columns are created
    add_index :sync_write_records, :primary_key_signature, 
              algorithm: :concurrently, 
              name: 'index_sync_write_records_on_primary_key_signature'
              
    add_index :sync_write_records, :data_signature, 
              algorithm: :concurrently,
              name: 'index_sync_write_records_on_data_signature'
  end

  def down
    # Remove indexes first
    remove_index :sync_write_records, name: 'index_sync_write_records_on_primary_key_signature'
    remove_index :sync_write_records, name: 'index_sync_write_records_on_data_signature'

    # Then remove columns
    remove_column :sync_write_records, :primary_key_signature
    remove_column :sync_write_records, :data_signature
    remove_column :sync_write_records, :destination_action
  end
end
