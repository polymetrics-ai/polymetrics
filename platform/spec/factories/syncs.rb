# frozen_string_literal: true

# spec/factories/syncs.rb
FactoryBot.define do
  factory :sync do
    connection
    stream_name { Random.uuid }
    status { :synced }
    sync_mode { :full_refresh_overwrite }
    sync_frequency { "0 0 * * *" }
    schedule_type { :scheduled }
    schema { { "type" => "object", "properties" => {} } }
    supported_sync_modes { %w[full_refresh incremental] }
    source_defined_cursor { false }
    default_cursor_field { [] }
    source_defined_primary_key { [] }
    destination_sync_mode { "overwrite" }

    trait :syncing do
      status { :syncing }
    end

    trait :queued do
      status { :queued }
    end

    trait :error do
      status { :error }
    end

    trait :action_required do
      status { :action_required }
    end

    trait :manual do
      schedule_type { :manual }
      sync_frequency { nil }
    end

    trait :cron do
      schedule_type { :cron }
      sync_frequency { "*/5 * * * *" }
    end
  end
end
