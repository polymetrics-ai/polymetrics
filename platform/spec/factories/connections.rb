# frozen_string_literal: true

FactoryBot.define do
  factory :connection do
    workspace
    association :source, factory: :connector
    association :destination, factory: :connector
    name { Faker::Name.unique.name }
    schedule_type { :scheduled }
    sync_frequency { "0 0 * * *" }
    configuration { { "key" => "value" } }
    stream_prefix { Faker::Internet.domain_word }

    trait :manual do
      schedule_type { :manual }
      sync_frequency { nil }
    end

    trait :cron do
      schedule_type { :cron }
      sync_frequency { "*/5 * * * *" }
    end

    trait :failed do
      status { :failed }
    end

    trait :running do
      status { :running }
    end

    trait :paused do
      status { :paused }
    end
  end
end
