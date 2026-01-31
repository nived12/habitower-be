# frozen_string_literal: true

require "rails_helper"

RSpec.describe("POST /api/v1/groups", type: :request) do
  let(:user) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: user) }

  subject(:do_request) do
    post "/api/v1/groups", params: request_params.to_json, headers: auth_headers(user)
  end

  context "with valid params for a public group" do
    let(:request_params) do
      {
        group: {
          challenge_template_id: challenge_template.id,
          privacy_type: "public"
        }
      }
    end

    it "returns 201 Created" do
      do_request
      expect(response).to(have_http_status(:created))
    end

    it "creates a new group" do
      expect { do_request }.to(change(Group, :count).by(1))
    end

    it "creates an admin membership for the creator" do
      do_request
      group = Group.last
      membership = group.memberships.find_by(user: user)

      expect(membership).to(be_present)
      expect(membership.role).to(eq("admin"))
    end

    it "returns the group attributes" do
      do_request
      expect(parsed_body["challenge_template_id"]).to(eq(challenge_template.id))
      expect(parsed_body["creator_id"]).to(eq(user.id))
      expect(parsed_body["privacy_type"]).to(eq("public"))
    end

    it "does not set invite_code for public groups" do
      do_request
      expect(Group.last.invite_code).to(be_nil)
    end
  end

  context "with valid params for a private group" do
    let(:request_params) do
      {
        group: {
          challenge_template_id: challenge_template.id,
          privacy_type: "private"
        }
      }
    end

    it "creates a private group" do
      do_request
      expect(parsed_body["privacy_type"]).to(eq("private"))
    end

    it "generates an invite_code" do
      do_request
      expect(Group.last.invite_code).to(be_present)
      expect(Group.last.invite_code.length).to(eq(6))
    end
  end

  context "with explicit start_date" do
    let(:custom_date) { (Date.current + 1.month).beginning_of_month.to_s }
    let(:request_params) do
      {
        group: {
          challenge_template_id: challenge_template.id,
          start_date: custom_date
        }
      }
    end

    it "uses the provided start_date" do
      do_request
      expect(parsed_body["start_date"]).to(eq(custom_date))
    end
  end

  context "with invalid challenge_template_id" do
    let(:request_params) do
      {
        group: {
          challenge_template_id: 999999
        }
      }
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    let(:request_params) { { group: { challenge_template_id: challenge_template.id } } }

    subject(:do_request) do
      post "/api/v1/groups", params: request_params.to_json, headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
