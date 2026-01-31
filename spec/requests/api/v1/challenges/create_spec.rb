# frozen_string_literal: true

require "rails_helper"

RSpec.describe("POST /api/v1/challenges", type: :request) do
  let(:user) { create(:user) }

  subject(:do_request) do
    post "/api/v1/challenges", params: request_params.to_json, headers: auth_headers(user)
  end

  context "with valid params" do
    let(:request_params) do
      {
        challenge: {
          title: "30 Day Fitness Challenge",
          description: "Build healthy exercise habits",
          period_type: "weekly",
          privacy_type: "public"
        }
      }
    end

    it "returns 201 Created" do
      do_request
      expect(response).to(have_http_status(:created))
    end

    it "creates a new challenge" do
      expect { do_request }.to(change(Challenge, :count).by(1))
    end

    it "sets the current user as creator" do
      do_request
      expect(parsed_body["creator_id"]).to(eq(user.id))
    end

    it "returns the challenge attributes" do
      do_request
      expect(parsed_body["title"]).to(eq("30 Day Fitness Challenge"))
      expect(parsed_body["description"]).to(eq("Build healthy exercise habits"))
      expect(parsed_body["period_type"]).to(eq("weekly"))
      expect(parsed_body["privacy_type"]).to(eq("public"))
    end
  end

  context "with private privacy_type" do
    let(:request_params) do
      {
        challenge: {
          title: "Personal Challenge",
          privacy_type: "private"
        }
      }
    end

    it "creates a private challenge" do
      do_request
      expect(parsed_body["privacy_type"]).to(eq("private"))
    end
  end

  context "with monthly period_type" do
    let(:request_params) do
      {
        challenge: {
          title: "Monthly Challenge",
          period_type: "monthly"
        }
      }
    end

    it "creates a monthly challenge" do
      do_request
      expect(parsed_body["period_type"]).to(eq("monthly"))
    end
  end

  context "with invalid params" do
    let(:request_params) { { challenge: { title: "" } } }

    before { do_request }

    it "returns 422 Unprocessable Entity" do
      expect(response).to(have_http_status(:unprocessable_content))
    end

    it "returns validation errors" do
      expect(parsed_body["errors"]).to(be_present)
      expect(parsed_body["errors"].first["detail"]).to(include("blank"))
    end
  end

  context "when not authenticated" do
    let(:request_params) { { challenge: { title: "Test" } } }

    subject(:do_request) do
      post "/api/v1/challenges", params: request_params.to_json, headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
