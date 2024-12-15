# frozen_string_literal: true

class AddSignaturesAndDestinationActionToSyncWriteRecords < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Add columns in bulk
    change_table :sync_write_records, bulk: true do |t|
      t.string :primary_key_signature
      t.string :data_signature
      t.integer :destination_action, default: 0, null: false
    end

    # Add indexes after columns are created
    add_index :sync_write_records, :primary_key_signature,
              algorithm: :concurrently,
              name: "index_sync_write_records_on_primary_key_signature"

    add_index :sync_write_records, :data_signature,
              algorithm: :concurrently,
              name: "index_sync_write_records_on_data_signature"
  end

  def down
    # Remove indexes first
    remove_index :sync_write_records, name: "index_sync_write_records_on_primary_key_signature"
    remove_index :sync_write_records, name: "index_sync_write_records_on_data_signature"

    # Remove columns in bulk
    change_table :sync_write_records, bulk: true do |t|
      t.remove :primary_key_signature
      t.remove :data_signature
      t.remove :destination_action
    end
  end
end
