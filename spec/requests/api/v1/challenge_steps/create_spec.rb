# frozen_string_literal: true

require "rails_helper"

RSpec.describe("POST /api/v1/challenges/:challenge_id/challenge_steps", type: :request) do
  let(:creator) { create(:user) }
  let(:other_user) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }

  subject(:do_request) do
    post "/api/v1/challenges/#{challenge.id}/challenge_steps",
      params: request_params.to_json,
      headers: auth_headers(user)
  end

  context "when user is the challenge creator" do
    let(:user) { creator }

    context "with valid params" do
      let(:request_params) do
        {
          challenge_step: {
            title: "Morning Meditation",
            position: 1,
            requirements: { duration_minutes: 10 }
          }
        }
      end

      it "returns 201 Created" do
        do_request
        expect(response).to(have_http_status(:created))
      end

      it "creates a new challenge step" do
        expect { do_request }.to(change(ChallengeStep, :count).by(1))
      end

      it "sets the current user as creator" do
        do_request
        expect(parsed_body["creator_id"]).to(eq(user.id))
      end

      it "returns the challenge step attributes" do
        do_request
        expect(parsed_body["title"]).to(eq("Morning Meditation"))
        expect(parsed_body["position"]).to(eq(1))
        expect(parsed_body["requirements"]).to(eq({ "duration_minutes" => 10 }))
        expect(parsed_body["challenge_id"]).to(eq(challenge.id))
      end
    end

    context "with invalid params" do
      let(:request_params) { { challenge_step: { title: "" } } }

      before { do_request }

      it "returns 422 Unprocessable Entity" do
        expect(response).to(have_http_status(:unprocessable_entity))
      end

      it "returns validation errors" do
        expect(parsed_body["errors"]).to(be_present)
      end
    end
  end

  context "when user is not the challenge creator" do
    let(:user) { other_user }
    let(:request_params) { { challenge_step: { title: "Hacked Step", position: 1 } } }

    before { do_request }

    it "returns 403 Forbidden" do
      expect(response).to(have_http_status(:forbidden))
    end

    it "does not create a challenge step" do
      expect(ChallengeStep.where(title: "Hacked Step")).not_to(exist)
    end
  end

  context "when not authenticated" do
    let(:request_params) { { challenge_step: { title: "Test", position: 1 } } }

    subject(:do_request) do
      post "/api/v1/challenges/#{challenge.id}/challenge_steps",
        params: request_params.to_json,
        headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
