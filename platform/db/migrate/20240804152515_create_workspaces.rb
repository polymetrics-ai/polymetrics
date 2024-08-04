# frozen_string_literal: true

class CreateWorkspaces < ActiveRecord::Migration[7.1]
  def change
    create_table :workspaces do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
