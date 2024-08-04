# frozen_string_literal: true

class AddUniqueIndexToUsersEmail < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :users, %i[email provider], unique: true, algorithm: :concurrently
  end
end
