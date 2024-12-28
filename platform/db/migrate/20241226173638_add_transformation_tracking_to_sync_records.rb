# frozen_string_literal: true

class AddTransformationTrackingToSyncRecords < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :sync_read_records, :transformation_completed_at, :datetime

    change_table :sync_runs, bulk: true do |t|
      t.boolean :transformation_completed, null: false, default: false
      t.datetime :last_transformed_at
    end

    add_index :sync_runs, %i[sync_id last_transformed_at], algorithm: :concurrently
  end
end
