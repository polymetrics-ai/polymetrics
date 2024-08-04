# frozen_string_literal: true

class AddUniqueIndexToWorkspaces < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :workspaces, %i[name organization_id], unique: true, algorithm: :concurrently
  end
end
