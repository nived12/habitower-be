# frozen_string_literal: true

FactoryBot.define do
  factory :refresh_token do
    association :user
    token { SecureRandom.urlsafe_base64(32) }
    expires_at { 30.days.from_now }
  end
end
