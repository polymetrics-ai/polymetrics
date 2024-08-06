# frozen_string_literal: true

class CreateUserWorkspaceMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :user_workspace_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :workspace, null: false, foreign_key: true
      t.string :role, null: false
      t.index %i[user_id workspace_id], unique: true,
                                        name: "index_user_workspace_memberships_on_user_id_and_workspace_id"

      t.timestamps
    end
  end
end
