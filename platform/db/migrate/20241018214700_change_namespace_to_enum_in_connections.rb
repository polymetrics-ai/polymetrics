# frozen_string_literal: true

class ChangeNamespaceToEnumInConnections < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      remove_column :connections, :namespace
      add_column :connections, :namespace, :integer
    end
  end

  def down
    safety_assured do
      remove_column :connections, :namespace
      add_column :connections, :namespace, :string
    end
  end
end
