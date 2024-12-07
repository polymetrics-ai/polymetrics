# frozen_string_literal: true

class AddCursorFieldsToSyncRuns < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    change_table :sync_runs, bulk: true do |t|
      t.integer :current_page, default: 1
      t.integer :total_pages
      t.integer :current_offset, default: 0
      t.integer :batch_size, default: 1000
      t.string :last_cursor_value
      t.datetime :last_extracted_at
      t.boolean :extraction_completed, default: false, null: false
      t.integer :records_extracted, default: 0
    end

    add_index :sync_runs, %i[sync_id last_cursor_value], algorithm: :concurrently
    add_index :sync_runs, %i[sync_id current_page], algorithm: :concurrently
    add_index :sync_runs, %i[sync_id last_extracted_at], algorithm: :concurrently
  end
end
