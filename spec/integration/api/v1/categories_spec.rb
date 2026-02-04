# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("Categories API", type: :request) do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }

  path "/api/v1/categories" do
    get "List categories" do
      tags "Categories"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("categories"))
          expect(data["categories"]).to(be_an(Array))
        end
      end
    end
  end
end
