# frozen_string_literal: true

FactoryBot.define do
  factory :sync_log do
    sync_run
    log_type { :info }
    message { "This is a test log message" }
    emitted_at { Time.current }

    trait :warn do
      log_type { :warn }
      message { "This is a warning message" }
    end

    trait :error do
      log_type { :error }
      message { "This is an error message" }
    end

    trait :debug do
      log_type { :debug }
      message { "This is a debug message" }
    end

    trait :long_message do
      message { "a" * 1000 } # A long message with 1000 characters
    end

    trait :future_emission do
      emitted_at { 1.day.from_now }
    end

    trait :past_emission do
      emitted_at { 1.day.ago }
    end
  end
end
