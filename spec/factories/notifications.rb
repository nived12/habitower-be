# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    association :recipient, factory: :user
    association :actor, factory: :user
    action { "high_five" }
    read_at { nil }
    data { {} }
  end
end
