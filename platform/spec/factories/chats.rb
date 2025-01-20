# frozen_string_literal: true

FactoryBot.define do
  factory :chat do
    workspace
    user
    title { Faker::Lorem.sentence }
    status { :active }

    trait :completed do
      status { :completed }
    end

    trait :failed do
      status { :failed }
    end

    trait :with_messages do
      transient do
        messages_count { 3 }
      end

      after(:create) do |chat, evaluator|
        create_list(:message, evaluator.messages_count, chat: chat)
      end
    end

    trait :with_pipeline do
      after(:create) do |chat|
        create(:message, :with_pipeline, chat: chat)
      end
    end
  end
end
