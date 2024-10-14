# frozen_string_literal: true

class CreateSyncs < ActiveRecord::Migration[7.1]
  # rubocop:disable Metrics/MethodLength
  def change
    create_table :syncs do |t|
      t.references :connection, null: false, foreign_key: true
      t.string :stream_name, null: false
      t.integer :status, null: false, default: 0
      t.integer :sync_mode, null: false
      t.string :sync_frequency, null: false
      t.integer :schedule_type, null: false, default: 0
      t.jsonb :schema
      t.string :supported_sync_modes, array: true
      t.boolean :source_defined_cursor, null: false, default: false
      t.string :default_cursor_field, array: true
      t.string :source_defined_primary_key, array: true
      t.string :destination_sync_mode

      t.timestamps
    end

    add_index :syncs, %i[connection_id stream_name], unique: true
  end
  # rubocop:enable Metrics/MethodLength
end
