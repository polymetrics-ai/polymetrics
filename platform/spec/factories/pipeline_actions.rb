# frozen_string_literal: true

FactoryBot.define do
  factory :pipeline_action do
    pipeline
    sequence(:position) { |n| n }
    action_type { :connector_selection }
    action_data do
      {
        "source" => { "connector_id" => create(:connector).id },
        "destination" => { "connector_id" => create(:connector).id }
      }
    end

    trait :connector_selection do
      action_type { :connector_selection }
      action_data do
        {
          "source" => { "connector_id" => create(:connector).id },
          "destination" => { "connector_id" => create(:connector).id }
        }
      end
    end

    trait :query_execution do
      action_type { :query_execution }
      action_data do
        {
          "query" => "SELECT * FROM users",
          "connection_id" => create(:connection).id
        }
      end
    end

    trait :with_result do
      result_data do
        {
          "execution_status" => "completed",
          "error_message" => nil,
          "output" => { "rows_affected" => 10 }
        }
      end
    end

    trait :connection_creation do
      action_type { :connection_creation }
      action_data do
        {
          "streams" => ["users"],
          "created_at" => Time.current.iso8601,
          "connection_id" => create(:connection).id
        }
      end
    end

    trait :sync_initialization do
      action_type { :sync_initialization }
      action_data do
        {
          "connection_id" => create(:connection).id,
          "connection_workflow_run_id" => SecureRandom.uuid
        }
      end
    end
  end
end
