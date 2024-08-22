# frozen_string_literal: true

FactoryBot.define do
  factory :connector do
    workspace
    sequence(:name) { |n| "Connector #{n}" }
    connector_class_name { "github" }
    description { "A connector for GitHub" }
    connector_language { :ruby }
    configuration { { "access_token" => "sample_token" } }
  end
end
