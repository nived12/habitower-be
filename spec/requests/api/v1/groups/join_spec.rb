# frozen_string_literal: true

require "rails_helper"

RSpec.describe("POST /api/v1/groups/:group_id/memberships (join)", type: :request) do
  let(:user) { create(:user) }
  let(:creator) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator) }

  subject(:do_request) do
    post "/api/v1/groups/#{group.id}/memberships", params: request_params.to_json, headers: auth_headers(user)
  end

  context "with a public group" do
    let(:group) { create(:group, challenge_template: challenge_template, creator: creator) }
    let(:request_params) { {} }

    it "returns 201 Created" do
      do_request
      expect(response).to(have_http_status(:created))
    end

    it "creates a membership" do
      expect { do_request }.to(change(Membership, :count).by(1))
    end

    it "returns the membership" do
      do_request
      expect(parsed_body["user_id"]).to(eq(user.id))
      expect(parsed_body["group_id"]).to(eq(group.id))
      expect(parsed_body["role"]).to(eq("member"))
    end
  end

  context "with a private group" do
    let(:group) do
      create(
        :group, challenge_template: challenge_template, creator: creator, privacy_type: "private",
        invite_code: "ABC123"
      )
    end

    context "with valid invite_code" do
      let(:request_params) { { invite_code: "ABC123" } }

      it "returns 201 Created" do
        do_request
        expect(response).to(have_http_status(:created))
      end

      it "creates a membership" do
        expect { do_request }.to(change(Membership, :count).by(1))
      end
    end

    context "with invalid invite_code" do
      let(:request_params) { { invite_code: "WRONG1" } }

      before { do_request }

      it "returns 403 Forbidden" do
        expect(response).to(have_http_status(:forbidden))
      end

      it "returns an error message" do
        expect(parsed_body["errors"].first["detail"]).to(eq("Invalid invite code"))
      end
    end

    context "without invite_code" do
      let(:request_params) { {} }

      before { do_request }

      it "returns 403 Forbidden" do
        expect(response).to(have_http_status(:forbidden))
      end
    end
  end

  context "when user is already a member" do
    let(:group) { create(:group, challenge_template: challenge_template, creator: creator) }
    let!(:membership) { create(:membership, group: group, user: user) }
    let(:request_params) { {} }

    before { do_request }

    it "returns 422 Unprocessable Entity" do
      expect(response).to(have_http_status(:unprocessable_content))
    end

    it "returns an error message" do
      expect(parsed_body["errors"].first["detail"]).to(eq("User is already a member of this group"))
    end
  end

  context "when group does not exist" do
    let(:request_params) { {} }

    subject(:do_request) do
      post "/api/v1/groups/999999/memberships", params: request_params.to_json, headers: auth_headers(user)
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    let(:group) { create(:group, challenge_template: challenge_template, creator: creator) }
    let(:request_params) { {} }

    subject(:do_request) do
      post "/api/v1/groups/#{group.id}/memberships", params: request_params.to_json, headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
