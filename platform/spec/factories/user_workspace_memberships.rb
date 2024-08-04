# frozen_string_literal: true

FactoryBot.define do
  factory :user_workspace_membership do
    user
    workspace
    role { "member" }
  end
end
