# frozen_string_literal: true

class AddOrganizationNameToUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :users, :organization_name, :string
    add_index :users, :organization_name, algorithm: :concurrently
  end
end
