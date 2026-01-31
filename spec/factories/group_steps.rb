# frozen_string_literal: true

FactoryBot.define do
  factory :group_step do
    association :group
    association :creator, factory: :user
    sequence(:title) { |n| "Step #{n}" }
    sequence(:position) { |n| n }
    requirements { {} }
  end
end
