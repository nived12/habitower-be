# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("Follows API", type: :request) do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
  let(:followed) { create(:user) }

  path "/api/v1/follows" do
    get "List users the current user follows" do
      tags "Follows"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("following"))
        end
      end
    end

    post "Follow a user" do
      tags "Follows"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          followed_id: { type: :integer }
        },
        required: ["followed_id"]
      }

      response "201", "created" do
        let(:body) { { followed_id: followed.id } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("follow"))
          expect(data["follow"]["followed_id"]).to(eq(followed.id))
        end
      end
    end
  end

  path "/api/v1/followers" do
    get "List followers of the current user" do
      tags "Follows"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("followers"))
        end
      end
    end
  end
end
