# frozen_string_literal: true

class CreateSyncReadRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :sync_read_records do |t|
      t.references :sync_run, null: false, foreign_key: true
      t.jsonb :data, null: false
      t.string :signature, null: false

      t.timestamps
    end

    add_index :sync_read_records, %i[sync_run_id signature], unique: true
  end
end
