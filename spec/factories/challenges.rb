# frozen_string_literal: true

FactoryBot.define do
  factory :challenge do
    sequence(:title) { |n| "Challenge #{n}" }
    description { "A challenge" }
    period_type { "weekly" }
    privacy_type { "public" }
    association :creator, factory: :user

    trait :private do
      privacy_type { "private" }
    end
  end
end
