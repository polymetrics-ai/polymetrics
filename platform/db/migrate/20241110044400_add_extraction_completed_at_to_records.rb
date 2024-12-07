# frozen_string_literal: true

class AddExtractionCompletedAtToRecords < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :sync_read_records, :extraction_completed_at, :datetime
    add_column :sync_write_records, :extraction_completed_at, :datetime

    add_reference :sync_write_records, :sync_read_record, index: { algorithm: :concurrently }
  end
end
