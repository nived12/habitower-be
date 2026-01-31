# frozen_string_literal: true

FactoryBot.define do
  factory :challenge_step, class: "ChallengeStepTemplate" do
    association :challenge_template, factory: :challenge
    sequence(:title) { |n| "Step #{n}" }
    sequence(:position) { |n| n }
    association :creator, factory: :user
  end
end
