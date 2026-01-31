# frozen_string_literal: true

require "rails_helper"

RSpec.describe("POST /api/v1/groups/:group_id/memberships", type: :request) do
  let(:admin) { create(:user, username: "admin_user") }
  let(:member) { create(:user, username: "regular_member") }
  let(:target_user) { create(:user, username: "target_user", email: "target@example.com") }
  let(:challenge) { create(:challenge, creator: admin) }
  let(:group) { create(:group, challenge: challenge, creator: admin) }
  let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }

  subject(:do_request) do
    post "/api/v1/groups/#{group.id}/memberships",
      params: request_params.to_json,
      headers: auth_headers(current_user)
  end

  context "when current_user is an admin" do
    let(:current_user) { admin }

    context "adding a user by email" do
      let(:request_params) { { identifier: target_user.email } }

      it "returns 201 Created" do
        do_request
        expect(response).to(have_http_status(:created))
      end

      it "creates a membership" do
        expect { do_request }.to(change(Membership, :count).by(1))
      end

      it "returns the membership" do
        do_request
        expect(parsed_body["user_id"]).to(eq(target_user.id))
        expect(parsed_body["group_id"]).to(eq(group.id))
        expect(parsed_body["role"]).to(eq("member"))
      end
    end

    context "adding a user by username" do
      let(:request_params) { { identifier: target_user.username } }

      it "creates a membership" do
        expect { do_request }.to(change(Membership, :count).by(1))
      end
    end

    context "adding a user as admin" do
      let(:request_params) { { identifier: target_user.email, role: "admin" } }

      it "creates an admin membership" do
        do_request
        expect(parsed_body["role"]).to(eq("admin"))
      end
    end

    context "when user is not found" do
      let(:request_params) { { identifier: "nonexistent@example.com" } }

      before { do_request }

      it "returns 404 Not Found" do
        expect(response).to(have_http_status(:not_found))
      end

      it "returns an error message" do
        expect(parsed_body["errors"].first["detail"]).to(include("User not found"))
      end
    end

    context "when user is already a member" do
      let!(:existing_membership) { create(:membership, group: group, user: target_user) }
      let(:request_params) { { identifier: target_user.email } }

      before { do_request }

      it "returns 422 Unprocessable Entity" do
        expect(response).to(have_http_status(:unprocessable_entity))
      end

      it "returns an error message" do
        expect(parsed_body["errors"].first["detail"]).to(include("already a member"))
      end
    end
  end

  context "when current_user is not an admin" do
    let(:current_user) { member }
    let!(:member_membership) { create(:membership, group: group, user: member, role: "member") }
    let(:request_params) { { identifier: target_user.email } }

    before { do_request }

    it "returns 403 Forbidden" do
      expect(response).to(have_http_status(:forbidden))
    end

    it "returns an error message" do
      expect(parsed_body["errors"].first["detail"]).to(include("Only group admins"))
    end
  end

  context "when not authenticated" do
    let(:request_params) { { identifier: target_user.email } }

    subject(:do_request) do
      post "/api/v1/groups/#{group.id}/memberships",
        params: request_params.to_json,
        headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
