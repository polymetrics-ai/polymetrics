# frozen_string_literal: true

class SetDefaultValuesForSyncRunPages < ActiveRecord::Migration[7.1]
  def up
    change_column_default :sync_runs, :current_page, from: 1, to: 0
    change_column_default :sync_runs, :total_pages, from: nil, to: 0
  end

  def down
    change_column_default :sync_runs, :current_page, from: 0, to: 1
    change_column_default :sync_runs, :total_pages, from: 0, to: nil
  end
end