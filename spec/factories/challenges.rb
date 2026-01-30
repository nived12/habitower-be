# frozen_string_literal: true

FactoryBot.define do
  factory :challenge do
    sequence(:title) { |n| "Challenge #{n}" }
    description { "A challenge" }
    period_type { "weekly" }
    association :creator, factory: :user
  end
end
