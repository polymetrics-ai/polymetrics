# frozen_string_literal: true

FactoryBot.define do
  factory :pipeline do
    message
    status { :pending }

    trait :running do
      status { :running }
    end

    trait :completed do
      status { :completed }
    end

    trait :failed do
      status { :failed }
    end

    trait :with_actions do
      transient do
        actions_count { 2 }
      end

      after(:create) do |pipeline, evaluator|
        create_list(:pipeline_action, evaluator.actions_count, pipeline: pipeline)
      end
    end
  end
end
