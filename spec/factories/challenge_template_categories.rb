# frozen_string_literal: true

FactoryBot.define do
  factory :challenge_template_category do
    association :challenge_template
    association :category
  end
end
