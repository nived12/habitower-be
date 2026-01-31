# frozen_string_literal: true

FactoryBot.define do
  factory :device do
    association :user
    platform { "ios" }
    token { "device-token-#{SecureRandom.hex(16)}" }
  end
end
