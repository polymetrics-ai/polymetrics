# frozen_string_literal: true

class AddUniqueIndexToConnectors < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :connectors, %i[workspace_id name configuration], unique: true,
                                                                name: "index_connectors_on_workspace_name_config", algorithm: :concurrently
  end
end
