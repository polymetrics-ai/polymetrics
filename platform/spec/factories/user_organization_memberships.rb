# frozen_string_literal: true

FactoryBot.define do
  factory :user_organization_membership do
    user
    organization
    role { "member" }
  end
end
