# frozen_string_literal: true

FactoryBot.define do
  factory :sync_read_record do
    sync_run
    sync
    data { { "key" => "value" } }

    trait :complex_data do
      data { { "nested" => { "array" => [1, 2, 3], "object" => { "key" => "value" } } } }
    end

    trait :large_data do
      data { { "large_key" => "a" * 1000 } }
    end

    trait :empty_data do
      data { {} }
    end

    trait :null_values do
      data { { "null_key" => nil } }
    end

    trait :special_characters do
      data { { "special" => "!@#$%^&*()" } }
    end
  end
end
