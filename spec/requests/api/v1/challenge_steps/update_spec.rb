# frozen_string_literal: true

require "rails_helper"

RSpec.describe("PATCH /api/v1/challenges/:challenge_id/challenge_steps/:id", type: :request) do
  let(:creator) { create(:user) }
  let(:other_user) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }
  let(:challenge_step) { create(:challenge_step, challenge: challenge, creator: creator, title: "Original") }

  subject(:do_request) do
    patch "/api/v1/challenges/#{challenge.id}/challenge_steps/#{challenge_step.id}",
      params: request_params.to_json,
      headers: auth_headers(user)
  end

  context "when user is the challenge creator" do
    let(:user) { creator }

    context "with valid params" do
      let(:request_params) { { challenge_step: { title: "Updated Title" } } }

      before { do_request }

      it "returns 200 OK" do
        expect(response).to(have_http_status(:ok))
      end

      it "updates the challenge step" do
        expect(challenge_step.reload.title).to(eq("Updated Title"))
      end

      it "returns the updated challenge step" do
        expect(parsed_body["title"]).to(eq("Updated Title"))
      end
    end

    context "with invalid params" do
      let(:request_params) { { challenge_step: { title: "" } } }

      before { do_request }

      it "returns 422 Unprocessable Entity" do
        expect(response).to(have_http_status(:unprocessable_content))
      end
    end
  end

  context "when user is not the challenge creator" do
    let(:user) { other_user }
    let(:request_params) { { challenge_step: { title: "Hacked" } } }

    before { do_request }

    it "returns 403 Forbidden" do
      expect(response).to(have_http_status(:forbidden))
    end

    it "does not update the challenge step" do
      expect(challenge_step.reload.title).to(eq("Original"))
    end
  end

  context "when challenge step does not exist" do
    let(:user) { creator }
    let(:request_params) { { challenge_step: { title: "Test" } } }

    subject(:do_request) do
      patch "/api/v1/challenges/#{challenge.id}/challenge_steps/999999",
        params: request_params.to_json,
        headers: auth_headers(user)
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    let(:request_params) { { challenge_step: { title: "Test" } } }

    subject(:do_request) do
      patch "/api/v1/challenges/#{challenge.id}/challenge_steps/#{challenge_step.id}",
        params: request_params.to_json,
        headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
