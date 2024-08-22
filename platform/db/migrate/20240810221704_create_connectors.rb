# frozen_string_literal: true

class CreateConnectors < ActiveRecord::Migration[7.1]
  def change
    create_table :connectors do |t|
      t.references :workspace, null: false, foreign_key: true
      t.integer :connector_language
      t.jsonb :configuration
      t.string :name
      t.string :connector_class_name
      t.string :description
      t.boolean :connected, default: false, null: false

      t.timestamps
    end
  end
end
