# frozen_string_literal: true

class CreateUserOrganizationMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :user_organization_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end

    add_index :user_organization_memberships, %i[user_id organization_id], unique: true,
                                                                           name: "index_user_org_memberships_on_user_id_and_org_id"
  end
end
