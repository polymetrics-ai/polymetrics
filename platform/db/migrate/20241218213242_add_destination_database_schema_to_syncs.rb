# frozen_string_literal: true

class AddDestinationDatabaseSchemaToSyncs < ActiveRecord::Migration[7.1]
  def change
    add_column :syncs, :destination_database_schema, :jsonb
  end
end
