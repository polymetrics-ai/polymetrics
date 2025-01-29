# frozen_string_literal: true

class Chat < ApplicationRecord
  belongs_to :workspace
  belongs_to :user
  has_many :messages, dependent: :destroy
  has_many :pipelines, through: :messages
  has_many :chat_connections, dependent: :destroy
  has_many :connections, through: :chat_connections

  validates :title, presence: true
  validates :status, presence: true

  enum status: { active: 0, completed: 1, failed: 2 }

  scope :in_workspace, ->(workspace_id) { where(workspace_id: workspace_id) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
end
