# frozen_string_literal: true

class SetDefaultValuesForSyncRunPages < ActiveRecord::Migration[7.1]
  def up
    change_table :sync_runs, bulk: true do |t|
      t.change_default :current_page, from: 1, to: 0
      t.change_default :total_pages, from: nil, to: 0
    end
  end

  def down
    change_table :sync_runs, bulk: true do |t|
      t.change_default :current_page, from: 0, to: 1
      t.change_default :total_pages, from: 0, to: nil
    end
  end
end
