# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :chat
  has_one :pipeline, dependent: :destroy

  validates :content, presence: true
  validates :role, presence: true
  validates :message_type, presence: true

  enum role: { user: 0, system: 1, assistant: 2 }
  enum message_type: { text: 0, pipeline: 1, question: 2, summary: 3 }

  scope :pending_questions, -> { where(message_type: :question, answered: false) }
end
