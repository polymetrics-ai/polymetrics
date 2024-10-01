# frozen_string_literal: true

class Connection < ApplicationRecord
  belongs_to :workspace
  belongs_to :source, class_name: "Connector"
  belongs_to :destination, class_name: "Connector"
  has_many :syncs, dependent: :destroy

  enum status: { active: 0, inactive: 1, broken: 2 }

  validates :name, presence: true, uniqueness: { scope: :workspace_id }
  validates :status, presence: true

  serialize :configuration, JSON
end
