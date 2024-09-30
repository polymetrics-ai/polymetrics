# frozen_string_literal: true

class AddTypeToConnectors < ActiveRecord::Migration[7.1]
  def change
    add_column :connectors, :integration_type, :integer, default: 0, null: false
  end
end
