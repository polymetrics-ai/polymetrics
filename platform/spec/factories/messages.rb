# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    chat
    content { Faker::Lorem.paragraph }
    role { :user }
    message_type { :text }
    answered { false }

    # Role traits
    trait :user do
      role { :user }
    end

    trait :system do
      role { :system }
    end

    trait :assistant do
      role { :assistant }
    end

    # Type traits
    trait :text do
      message_type { :text }
    end

    trait :pipeline do
      message_type { :pipeline }
    end

    trait :question do
      message_type { :question }
    end

    # Association traits
    trait :with_pipeline do
      message_type { :pipeline }

      after(:create) do |message|
        create(:pipeline, message: message)
      end
    end

    # Composite traits
    trait :answered_question do
      question
      answered { true }
    end

    trait :pending_question do
      question
      answered { false }
    end
  end
end
