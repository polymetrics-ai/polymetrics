# frozen_string_literal: true

class CreateConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :connections do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :source, null: false, foreign_key: { to_table: :connectors }
      t.references :destination, null: false, foreign_key: { to_table: :connectors }
      t.string :name, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :configuration

      t.timestamps
    end

    add_index :connections, %i[workspace_id name], unique: true
  end
end
