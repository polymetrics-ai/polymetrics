# frozen_string_literal: true

# db/migrate/20240802115755_optimize_users_table_structure.rb
class OptimizeUsersTableStructure < ActiveRecord::Migration[7.1]
  def up
    change_table :users, bulk: true do |t|
      t.integer :sign_in_count, default: 0, null: false unless column_exists?(:users, :sign_in_count)
      t.datetime :current_sign_in_at unless column_exists?(:users, :current_sign_in_at)
      t.datetime :last_sign_in_at unless column_exists?(:users, :last_sign_in_at)
      t.string :current_sign_in_ip unless column_exists?(:users, :current_sign_in_ip)
      t.string :last_sign_in_ip unless column_exists?(:users, :last_sign_in_ip)
    end
  end

  def down
    # No need for a down method as we're not making any new changes
    # that need to be reversed
  end
end
