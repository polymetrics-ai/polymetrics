# frozen_string_literal: true

class UpdateOrganizationNameConstraints < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :organizations, :name, unique: true, algorithm: :concurrently
  end
end
