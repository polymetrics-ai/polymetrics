class RemoveNamespaceNewFromConnections < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :connections, :namespace_new, :integer }
  end
end
