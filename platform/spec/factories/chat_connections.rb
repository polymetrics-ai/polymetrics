# frozen_string_literal: true

FactoryBot.define do
  factory :chat_connection do
    association :chat, factory: :chat
    association :connection, factory: :connection
  end
end
