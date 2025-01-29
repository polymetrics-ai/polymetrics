# frozen_string_literal: true

class ChatConnection < ApplicationRecord
  belongs_to :chat
  belongs_to :connection

  validates :chat_id, uniqueness: { scope: :connection_id }
end
