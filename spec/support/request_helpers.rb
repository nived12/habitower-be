# frozen_string_literal: true

module RequestHelpers
  def json_headers
    { "Content-Type" => "application/json", "Accept" => "application/json" }
  end

  def auth_headers(user)
    token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
    json_headers.merge("Authorization" => "Bearer #{token}")
  end

  def parsed_body
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include(RequestHelpers, type: :request)
end
