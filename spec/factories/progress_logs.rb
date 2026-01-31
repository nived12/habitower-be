# frozen_string_literal: true

FactoryBot.define do
  factory :progress_log do
    association :membership
    association :group_step
    value { 1 }
    occurred_at { Time.current }
  end
end
