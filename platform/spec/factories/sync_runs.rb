# frozen_string_literal: true

FactoryBot.define do
  factory :sync_run do
    sync
    status { :running }
    started_at { Time.current }
    completed_at { nil }
    total_records_read { 0 }
    total_records_written { 0 }
    successful_records_read { 0 }
    failed_records_read { 0 }
    successful_records_write { 0 }
    records_failed_to_write { 0 }

    trait :succeeded do
      status { :succeeded }
      completed_at { Time.current }
    end

    trait :failed do
      status { :failed }
      completed_at { Time.current }
    end
  end
end
