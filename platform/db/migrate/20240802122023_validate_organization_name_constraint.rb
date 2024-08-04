# frozen_string_literal: true

# db/migrate/YYYYMMDDHHMMSS_validate_organization_name_constraint.rb
class ValidateOrganizationNameConstraint < ActiveRecord::Migration[7.1]
  def up
    validate_check_constraint :organizations, name: "organizations_name_null"
    change_column_null :organizations, :name, false
    remove_check_constraint :organizations, name: "organizations_name_null"
  end

  def down
    change_column_null :organizations, :name, true
  end
end
