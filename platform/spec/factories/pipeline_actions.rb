# frozen_string_literal: true

FactoryBot.define do
  factory :pipeline_action do
    pipeline
    sequence(:position) { |n| n }
    action_type { :connection_creation }
    action_data do
      {
        "source_connector_id" => create(:connector).id,
        "streams" => %w[users orders]
      }
    end

    trait :connection_creation do
      action_type { :connection_creation }
      action_data do
        {
          "source_connector_id" => create(:connector).id,
          "streams" => %w[users orders]
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

    trait :summary_generation do
      action_type { :summary_generation }
      association :query_action, factory: %i[pipeline_action query_execution]
      action_data { { "summary_description" => "Summarize user data" } }
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
  end
end
