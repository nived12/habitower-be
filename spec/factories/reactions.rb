# frozen_string_literal: true

FactoryBot.define do
  factory :reaction do
    association :user
    association :progress_log
    kind { "high_five" }
  end
end
