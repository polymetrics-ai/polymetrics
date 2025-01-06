# frozen_string_literal: true

class SetDefaultNamespaceForConnections < ActiveRecord::Migration[7.1]
  def up
    change_column_default :connections, :namespace, 0
  end

  def down
    change_column_default :connections, :namespace, nil
  end
end
