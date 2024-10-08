# frozen_string_literal: true

class CreateSyncWriteRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :sync_write_records do |t|
      t.references :sync_run, null: false, foreign_key: true
      t.references :sync, null: false, foreign_key: true
      t.jsonb :data, null: false
      t.string :signature, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :sync_write_records, :signature
  end
end
