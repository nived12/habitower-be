# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("Groups API", type: :request) do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
  let(:challenge_template) { create(:challenge_template, creator: user) }

  path "/api/v1/groups" do
    get "List groups" do
      tags "Groups"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        let!(:group) { create(:group, challenge_template: challenge_template, creator: user) }

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
        let(:group) { { group: { challenge_template_id: challenge_template.id, privacy_type: "public" } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["challenge_template_id"]).to(eq(challenge_template.id))
          expect(data["creator_id"]).to(eq(user.id))
        end
      end

      response "404", "challenge not found" do
        let(:group) { { group: { challenge_template_id: 999999 } } }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        let(:group) { { group: { challenge_template_id: challenge_template.id } } }
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
        let(:existing_group) { create(:group, challenge_template: challenge_template, creator: user) }
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
        let(:private_group) do
          create(:group, challenge_template: challenge_template, creator: other_user, privacy_type: "private")
        end
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
        let(:existing_group) { create(:group, challenge_template: challenge_template, creator: user) }
        let(:id) { existing_group.id }
        let(:group_params) { { group: { privacy_type: "private" } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["privacy_type"]).to(eq("private"))
        end
      end

      response "403", "forbidden (not owner)" do
        let(:other_user) { create(:user) }
        let(:existing_group) { create(:group, challenge_template: challenge_template, creator: other_user) }
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
        let(:existing_group) { create(:group, challenge_template: challenge_template, creator: user) }
        let(:id) { existing_group.id }
        run_test!
      end

      response "403", "forbidden (not owner)" do
        let(:other_user) { create(:user) }
        let(:existing_group) { create(:group, challenge_template: challenge_template, creator: other_user) }
        let(:id) { existing_group.id }
        run_test!
      end
    end
  end

  path "/api/v1/groups/{group_id}/member-towers" do
    parameter name: :group_id, in: :path, type: :integer, required: true, description: "Group ID"

    get "List member towers (paginated, current user first)" do
      tags "Groups"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :page, in: :query, type: :integer, required: false, description: "Page number"
      parameter name: :per_page, in: :query, type: :integer, required: false, description: "Items per page"
      parameter name: :date, in: :query, type: :string, required: false,
        description: "Reference date (ISO) for ghost tower"
      parameter name: :user_timezone, in: :query, type: :string, required: false,
        description: "User timezone (e.g. UTC)"

      response "200", "success" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let!(:membership) { create(:membership, group: group, user: user) }
        let(:group_id) { group.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("meta"))
          expect(data["meta"]).to(include("page", "per_page", "total"))
          expect(data).to(have_key("member_towers"))
          expect(data["member_towers"]).to(be_an(Array))
          expect(data["member_towers"].first).to(include("is_current_user", "user", "integrity_score", "ghost_tower"))
        end
      end

      response "401", "unauthorized" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let(:group_id) { group.id }
        let(:Authorization) { nil }
        run_test!
      end

      response "404", "group not found" do
        let(:group_id) { 999999 }
        run_test!
      end
    end
  end

  path "/api/v1/groups/{group_id}/memberships/{id}/active-stack" do
    parameter name: :group_id, in: :path, type: :integer, required: true, description: "Group ID"
    parameter name: :id, in: :path, type: :integer, required: true, description: "Membership ID"

    get "Get membership active stack (today steps)" do
      tags "Groups"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :user_timezone, in: :query, type: :string, required: false, description: "User timezone"

      response "200", "success" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let!(:membership) { create(:membership, group: group, user: user) }
        let(:group_id) { group.id }
        let(:id) { membership.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(be_an(Array))
        end
      end

      response "401", "unauthorized" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let!(:membership) { create(:membership, group: group, user: user) }
        let(:group_id) { group.id }
        let(:id) { membership.id }
        let(:Authorization) { nil }
        run_test!
      end

      response "404", "membership not in group" do
        let(:other_group) { create(:group, challenge_template: challenge_template, creator: user) }
        let!(:other_membership) { create(:membership, group: other_group, user: user) }
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let(:group_id) { group.id }
        let(:id) { other_membership.id }
        run_test!
      end
    end
  end

  path "/api/v1/groups/{group_id}/memberships/{id}/integrity" do
    parameter name: :group_id, in: :path, type: :integer, required: true, description: "Group ID"
    parameter name: :id, in: :path, type: :integer, required: true, description: "Membership ID"

    get "Get membership integrity score" do
      tags "Groups"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :user_timezone, in: :query, type: :string, required: false, description: "User timezone"
      parameter name: :date, in: :query, type: :string, required: false, description: "Reference date (ISO)"

      response "200", "success" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let!(:membership) { create(:membership, group: group, user: user) }
        let(:group_id) { group.id }
        let(:id) { membership.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("integrity_score"))
        end
      end

      response "401", "unauthorized" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let!(:membership) { create(:membership, group: group, user: user) }
        let(:group_id) { group.id }
        let(:id) { membership.id }
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path "/api/v1/groups/{group_id}/memberships" do
    parameter name: :group_id, in: :path, type: :integer, required: true, description: "Group ID"

    get "List group memberships" do
      tags "Groups"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let!(:membership) { create(:membership, group: group, user: user) }
        let(:group_id) { group.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(be_an(Array))
          expect(data.first).to(have_key("user_id"))
          expect(data.first).to(have_key("user"))
        end
      end

      response "401", "unauthorized" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let(:group_id) { group.id }
        let(:Authorization) { nil }
        run_test!
      end

      response "404", "group not found" do
        let(:group_id) { 999999 }
        run_test!
      end
    end

    post "Create membership (join with invite_code, or admin add with identifier)" do
      tags "Groups"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          identifier: { type: :string, description: "Email or username (admin add only)" },
          invite_code: { type: :string, description: "Required for private groups when joining" },
          role: { type: :string, enum: %w[member admin], example: "member" }
        }
      }

      response "201", "joined successfully" do
        let(:other_user) { create(:user) }
        let(:group) { create(:group, challenge_template: challenge_template, creator: other_user) }
        let(:group_id) { group.id }
        let(:body) { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["user_id"]).to(eq(user.id))
          expect(data["role"]).to(eq("member"))
        end
      end

      response "201", "created" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let!(:admin_membership) { create(:membership, group: group, user: user, role: "admin") }
        let(:new_user) { create(:user) }
        let(:group_id) { group.id }
        let(:body) { { identifier: new_user.email, role: "member" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["user_id"]).to(eq(new_user.id))
          expect(data["role"]).to(eq("member"))
        end
      end

      response "403", "forbidden (not admin)" do
        let(:other_user) { create(:user) }
        let(:group) { create(:group, challenge_template: challenge_template, creator: other_user) }
        let!(:membership) { create(:membership, group: group, user: user, role: "member") }
        let(:group_id) { group.id }
        let(:body) { { identifier: "someone@example.com" } }
        run_test!
      end

      response "403", "invalid invite code" do
        let(:other_user) { create(:user) }
        let(:group) do
          create(
            :group, challenge_template: challenge_template, creator: other_user, privacy_type: "private",
            invite_code: "ABC123"
          )
        end
        let(:group_id) { group.id }
        let(:body) { { invite_code: "WRONG" } }
        run_test!
      end

      response "422", "already a member" do
        let(:other_user) { create(:user) }
        let(:group) { create(:group, challenge_template: challenge_template, creator: other_user) }
        let!(:membership) { create(:membership, group: group, user: user) }
        let(:group_id) { group.id }
        let(:body) { {} }
        run_test!
      end

      response "401", "unauthorized" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let(:group_id) { group.id }
        let(:body) { { identifier: "someone@example.com" } }
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path "/api/v1/groups/{group_id}/memberships/{id}" do
    parameter name: :group_id, in: :path, type: :integer, required: true, description: "Group ID"
    parameter name: :id, in: :path, type: :integer, required: true, description: "Membership ID"

    delete "Remove a member or leave (admin or own membership)" do
      tags "Groups"
      security [bearer_auth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "204", "left successfully" do
        let(:other_user) { create(:user) }
        let(:group) { create(:group, challenge_template: challenge_template, creator: other_user) }
        let!(:membership) { create(:membership, group: group, user: user) }
        let(:group_id) { group.id }
        let(:id) { membership.id }

        run_test!
      end

      response "204", "no content" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let!(:admin_membership) { create(:membership, group: group, user: user, role: "admin") }
        let(:member_user) { create(:user) }
        let!(:member_membership) { create(:membership, group: group, user: member_user, role: "member") }
        let(:group_id) { group.id }
        let(:id) { member_membership.id }

        run_test!
      end

      response "403", "forbidden (not admin)" do
        let(:other_user) { create(:user) }
        let(:group) { create(:group, challenge_template: challenge_template, creator: other_user) }
        let!(:membership) { create(:membership, group: group, user: user, role: "member") }
        let!(:other_member) { create(:membership, group: group, user: other_user, role: "member") }
        let(:group_id) { group.id }
        let(:id) { other_member.id }
        run_test!
      end

      response "403", "forbidden (creator cannot leave)" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let!(:membership) { create(:membership, group: group, user: user, role: "admin") }
        let(:group_id) { group.id }
        let(:id) { membership.id }
        run_test!
      end

      response "401", "unauthorized" do
        let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
        let!(:admin_membership) { create(:membership, group: group, user: user, role: "admin") }
        let(:member_user) { create(:user) }
        let!(:member_membership) { create(:membership, group: group, user: member_user) }
        let(:group_id) { group.id }
        let(:id) { member_membership.id }
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
