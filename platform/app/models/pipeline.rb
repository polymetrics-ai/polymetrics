# frozen_string_literal: true

class Pipeline < ApplicationRecord
  belongs_to :message
  has_many :pipeline_actions,
           -> { order(position: :asc) },
           dependent: :destroy,
           inverse_of: :pipeline

  validates :status, presence: true

  enum status: { pending: 0, running: 1, completed: 2, failed: 3 }
end
