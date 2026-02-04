# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("Devices API", type: :request) do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }

  path "/api/v1/devices" do
    post "Register or update a device for push notifications" do
      tags "Devices"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          platform: { type: :string, enum: %w[ios android], example: "ios" },
          token: { type: :string, description: "Device push token (APNs/FCM)" }
        },
        required: %w[platform token]
      }

      response "201", "created" do
        let(:body) { { platform: "ios", token: "device-token-123" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("id"))
          expect(data["platform"]).to(eq("ios"))
          expect(data["token"]).to(eq("device-token-123"))
        end
      end

      response "200", "updated (existing device)" do
        let!(:device) { create(:device, user: user, platform: "ios", token: "old-token") }
        let(:body) { { platform: "ios", token: "new-token" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["token"]).to(eq("new-token"))
        end
      end

      response "422", "invalid platform" do
        let(:body) { { platform: "web", token: "token" } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("errors"))
        end
      end

      response "422", "token required" do
        let(:body) { { platform: "ios", token: "" } }
        run_test!
      end

      response "401", "unauthorized" do
        let(:body) { { platform: "ios", token: "token" } }
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
