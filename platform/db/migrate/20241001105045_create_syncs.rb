# frozen_string_literal: true

class CreateSyncs < ActiveRecord::Migration[7.1]
  def change
    create_table :syncs do |t|
      t.references :connection, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :status, null: false, default: 0
      t.integer :sync_mode, null: false
      t.string :sync_frequency, null: false
      t.jsonb :schema
      t.string :supported_sync_modes, array: true
      t.boolean :source_defined_cursor
      t.string :default_cursor_field, array: true
      t.string :source_defined_primary_key, array: true
      t.string :destination_sync_mode

      t.timestamps
    end

    add_index :syncs, %i[connection_id name], unique: true
  end
end
