# frozen_string_literal: true

class AddCursorFieldsToSyncRuns < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :sync_runs, :current_page, :integer, default: 1
    add_column :sync_runs, :total_pages, :integer
    add_column :sync_runs, :current_offset, :integer, default: 0
    add_column :sync_runs, :batch_size, :integer, default: 1000
    add_column :sync_runs, :last_cursor_value, :string
    add_column :sync_runs, :last_extracted_at, :datetime
    add_column :sync_runs, :extraction_completed, :boolean, default: false
    add_column :sync_runs, :records_extracted, :integer, default: 0

    add_index :sync_runs, %i[sync_id last_cursor_value], algorithm: :concurrently
    add_index :sync_runs, %i[sync_id current_page], algorithm: :concurrently
    add_index :sync_runs, %i[sync_id last_extracted_at], algorithm: :concurrently
  end
end
