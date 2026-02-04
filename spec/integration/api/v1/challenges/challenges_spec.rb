# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("Challenges API", type: :request) do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }

  path "/api/v1/challenges" do
    get "List challenges" do
      tags "Challenges"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :category_id, in: :query, type: :integer, required: false, description: "Filter by category ID"
      parameter name: :category_slug, in: :query, type: :string, required: false, description: "Filter by category slug"

      response "200", "success" do
        let!(:challenge) { create(:challenge, creator: user) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(be_an(Array))
          expect(data.first["id"]).to(eq(challenge.id))
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end

    post "Create a challenge" do
      tags "Challenges"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :challenge, in: :body, schema: {
        type: :object,
        properties: {
          challenge: {
            type: :object,
            properties: {
              title: { type: :string, example: "30 Day Fitness Challenge" },
              description: { type: :string, example: "Build healthy exercise habits" },
              period_type: { type: :string, enum: %w[weekly monthly], example: "weekly" },
              privacy_type: { type: :string, enum: %w[public private], example: "public" },
              category_ids: { type: :array, items: { type: :integer },
description: "Category IDs to assign (e.g. [1, 2])" },
              rules: { type: :object, example: {} }
            },
            required: %w[title]
          }
        },
        required: ["challenge"]
      }

      response "201", "created" do
        let(:challenge) { { challenge: { title: "Test Challenge", description: "A test", period_type: "weekly" } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["title"]).to(eq("Test Challenge"))
          expect(data["creator_id"]).to(eq(user.id))
          expect(data).to(have_key("categories"))
        end
      end

      response "201", "created with categories" do
        let(:category) { create(:category, name: "Fitness", slug: "fitness") }
        let(:challenge) { { challenge: { title: "Fitness Challenge", category_ids: [category.id] } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["categories"]).to(be_an(Array))
          expect(data["categories"].first["slug"]).to(eq("fitness"))
        end
      end

      response "422", "validation error" do
        let(:challenge) { { challenge: { title: "" } } }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        let(:challenge) { { challenge: { title: "Test" } } }
        run_test!
      end
    end
  end

  path "/api/v1/challenges/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true, description: "Challenge ID"

    get "Get a challenge" do
      tags "Challenges"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        let(:challenge) { create(:challenge, creator: user) }
        let(:id) { challenge.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["id"]).to(eq(challenge.id))
          expect(data["title"]).to(eq(challenge.title))
          expect(data).to(have_key("categories"))
          expect(data["categories"]).to(be_an(Array))
        end
      end

      response "404", "not found" do
        let(:id) { 999999 }
        run_test!
      end

      response "403", "forbidden (private challenge)" do
        let(:other_user) { create(:user) }
        let(:challenge) { create(:challenge, :private, creator: other_user) }
        let(:id) { challenge.id }
        run_test!
      end
    end

    patch "Update a challenge" do
      tags "Challenges"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :challenge_params, in: :body, schema: {
        type: :object,
        properties: {
          challenge: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string },
              period_type: { type: :string, enum: %w[weekly monthly] },
              privacy_type: { type: :string, enum: %w[public private] },
              category_ids: { type: :array, items: { type: :integer },
description: "Category IDs to assign (replaces existing)" },
              rules: { type: :object }
            }
          }
        },
        required: ["challenge"]
      }

      response "200", "success" do
        let(:challenge) { create(:challenge, creator: user) }
        let(:id) { challenge.id }
        let(:challenge_params) { { challenge: { title: "Updated Title" } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["title"]).to(eq("Updated Title"))
        end
      end

      response "200", "success with category_ids" do
        let(:challenge) { create(:challenge, creator: user) }
        let(:category) { create(:category, name: "Fitness", slug: "fitness") }
        let(:id) { challenge.id }
        let(:challenge_params) { { challenge: { category_ids: [category.id] } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["categories"]).to(be_an(Array))
          expect(data["categories"].first["slug"]).to(eq("fitness"))
        end
      end

      response "403", "forbidden (not owner)" do
        let(:other_user) { create(:user) }
        let(:challenge) { create(:challenge, creator: other_user) }
        let(:id) { challenge.id }
        let(:challenge_params) { { challenge: { title: "Hacked" } } }
        run_test!
      end

      response "404", "not found" do
        let(:id) { 999999 }
        let(:challenge_params) { { challenge: { title: "Test" } } }
        run_test!
      end
    end

    delete "Delete a challenge" do
      tags "Challenges"
      security [bearer_auth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "204", "no content" do
        let(:challenge) { create(:challenge, creator: user) }
        let(:id) { challenge.id }
        run_test!
      end

      response "403", "forbidden (not owner)" do
        let(:other_user) { create(:user) }
        let(:challenge) { create(:challenge, creator: other_user) }
        let(:id) { challenge.id }
        run_test!
      end

      response "404", "not found" do
        let(:id) { 999999 }
        run_test!
      end
    end
  end
end
