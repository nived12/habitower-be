# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("Groups API", type: :request) do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
  let(:challenge) { create(:challenge, creator: user) }

  path "/api/v1/groups" do
    get "List groups" do
      tags "Groups"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        let!(:group) { create(:group, challenge: challenge, creator: user) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(be_an(Array))
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end

    post "Create a group" do
      tags "Groups"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :group, in: :body, schema: {
        type: :object,
        properties: {
          group: {
            type: :object,
            properties: {
              challenge_id: { type: :integer, example: 1 },
              privacy_type: { type: :string, enum: %w[public private], example: "public" },
              start_date: { type: :string, format: :date, example: "2026-02-01" }
            },
            required: %w[challenge_id]
          }
        },
        required: ["group"]
      }

      response "201", "created" do
        let(:group) { { group: { challenge_id: challenge.id, privacy_type: "public" } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["challenge_id"]).to(eq(challenge.id))
          expect(data["creator_id"]).to(eq(user.id))
        end
      end

      response "404", "challenge not found" do
        let(:group) { { group: { challenge_id: 999999 } } }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        let(:group) { { group: { challenge_id: challenge.id } } }
        run_test!
      end
    end
  end

  path "/api/v1/groups/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true, description: "Group ID"

    get "Get a group" do
      tags "Groups"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        let(:existing_group) { create(:group, challenge: challenge, creator: user) }
        let(:id) { existing_group.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["id"]).to(eq(existing_group.id))
        end
      end

      response "404", "not found" do
        let(:id) { 999999 }
        run_test!
      end

      response "403", "forbidden (private group)" do
        let(:other_user) { create(:user) }
        let(:private_group) { create(:group, challenge: challenge, creator: other_user, privacy_type: "private") }
        let(:id) { private_group.id }
        run_test!
      end
    end

    patch "Update a group" do
      tags "Groups"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :group_params, in: :body, schema: {
        type: :object,
        properties: {
          group: {
            type: :object,
            properties: {
              privacy_type: { type: :string, enum: %w[public private] }
            }
          }
        },
        required: ["group"]
      }

      response "200", "success" do
        let(:existing_group) { create(:group, challenge: challenge, creator: user) }
        let(:id) { existing_group.id }
        let(:group_params) { { group: { privacy_type: "private" } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["privacy_type"]).to(eq("private"))
        end
      end

      response "403", "forbidden (not owner)" do
        let(:other_user) { create(:user) }
        let(:existing_group) { create(:group, challenge: challenge, creator: other_user) }
        let(:id) { existing_group.id }
        let(:group_params) { { group: { privacy_type: "private" } } }
        run_test!
      end
    end

    delete "Delete a group" do
      tags "Groups"
      security [bearer_auth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "204", "no content" do
        let(:existing_group) { create(:group, challenge: challenge, creator: user) }
        let(:id) { existing_group.id }
        run_test!
      end

      response "403", "forbidden (not owner)" do
        let(:other_user) { create(:user) }
        let(:existing_group) { create(:group, challenge: challenge, creator: other_user) }
        let(:id) { existing_group.id }
        run_test!
      end
    end
  end

  path "/api/v1/groups/{id}/join" do
    parameter name: :id, in: :path, type: :integer, required: true, description: "Group ID"

    post "Join a group" do
      tags "Groups"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :join_params, in: :body, schema: {
        type: :object,
        properties: {
          invite_code: { type: :string, example: "ABC123", description: "Required for private groups" }
        }
      }

      response "201", "joined successfully" do
        let(:other_user) { create(:user) }
        let(:existing_group) { create(:group, challenge: challenge, creator: other_user) }
        let(:id) { existing_group.id }
        let(:join_params) { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["user_id"]).to(eq(user.id))
          expect(data["role"]).to(eq("member"))
        end
      end

      response "403", "invalid invite code" do
        let(:other_user) { create(:user) }
        let(:private_group) do
          create(:group, challenge: challenge, creator: other_user, privacy_type: "private", invite_code: "ABC123")
        end
        let(:id) { private_group.id }
        let(:join_params) { { invite_code: "WRONG" } }
        run_test!
      end

      response "422", "already a member" do
        let(:other_user) { create(:user) }
        let(:existing_group) { create(:group, challenge: challenge, creator: other_user) }
        let!(:membership) { create(:membership, group: existing_group, user: user) }
        let(:id) { existing_group.id }
        let(:join_params) { {} }
        run_test!
      end
    end
  end

  path "/api/v1/groups/{id}/leave" do
    parameter name: :id, in: :path, type: :integer, required: true, description: "Group ID"

    delete "Leave a group" do
      tags "Groups"
      security [bearer_auth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "204", "left successfully" do
        let(:other_user) { create(:user) }
        let(:existing_group) { create(:group, challenge: challenge, creator: other_user) }
        let!(:membership) { create(:membership, group: existing_group, user: user) }
        let(:id) { existing_group.id }
        run_test!
      end

      response "403", "forbidden (creator cannot leave)" do
        let(:existing_group) { create(:group, challenge: challenge, creator: user) }
        let!(:membership) { create(:membership, group: existing_group, user: user, role: "admin") }
        let(:id) { existing_group.id }
        run_test!
      end
    end
  end
end
