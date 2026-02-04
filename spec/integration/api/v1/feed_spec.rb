# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("Feed API", type: :request) do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }

  path "/api/v1/feed" do
    get "List feed items" do
      tags "Feed"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :scope, in: :query, type: :string, required: false, enum: %w[all mine friends],
        description: "Feed scope"
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "success" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("feed"))
          expect(data).to(have_key("meta"))
          expect(data["feed"]).to(be_an(Array))
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
