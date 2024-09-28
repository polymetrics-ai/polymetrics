# frozen_string_literal: true

class AddDefaultAnalyticsDbToConnectors < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :connectors, :default_analytics_db, :boolean, default: false, null: false
  end
end
