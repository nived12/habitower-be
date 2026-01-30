# frozen_string_literal: true

FactoryBot.define do
  factory :membership do
    association :user
    association :group
    role { "member" }
    status { "active" }
  end
end
