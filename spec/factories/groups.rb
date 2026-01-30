# frozen_string_literal: true

FactoryBot.define do
  factory :group do
    association :challenge
    start_date { Date.current }
    privacy_type { "public" }
    association :creator, factory: :user
  end
end
