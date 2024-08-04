# frozen_string_literal: true

FactoryBot.define do
  factory :workspace do
    sequence(:name) { |n| "Workspace #{n}" }
    organization
  end
end
