# frozen_string_literal: true

class CreateSyncReadRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :sync_read_records do |t|
      t.references :sync_run, null: false, foreign_key: true
      t.references :sync, null: false, foreign_key: true
      t.jsonb :data, null: false
      t.string :signature, null: false

      t.timestamps
    end
  end
end
