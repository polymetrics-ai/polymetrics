# frozen_string_literal: true

class AddCheckConstraintToOrganizationName < ActiveRecord::Migration[7.1]
  def change
    add_check_constraint :organizations, "name IS NOT NULL", name: "organizations_name_null", validate: false
  end
end
