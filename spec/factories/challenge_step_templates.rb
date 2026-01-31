# frozen_string_literal: true

FactoryBot.define do
  factory :challenge_step_template do
    association :challenge_template
    sequence(:title) { |n| "Step #{n}" }
    sequence(:position) { |n| n }
    association :creator, factory: :user
  end
end
