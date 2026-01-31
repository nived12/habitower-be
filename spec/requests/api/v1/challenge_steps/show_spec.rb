# frozen_string_literal: true

require "rails_helper"

RSpec.describe("GET /api/v1/challenges/:challenge_id/challenge_steps/:id", type: :request) do
  let(:user) { create(:user) }
  let(:creator) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }
  let(:challenge_step) { create(:challenge_step, challenge_template: challenge, creator: creator) }

  subject(:do_request) do
    get "/api/v1/challenges/#{challenge.id}/challenge_steps/#{challenge_step.id}", headers: auth_headers(user)
  end

  context "when challenge is public" do
    before { do_request }

    it "returns 200 OK" do
      expect(response).to(have_http_status(:ok))
    end

    it "returns the challenge step attributes" do
      expect(parsed_body["id"]).to(eq(challenge_step.id))
      expect(parsed_body["title"]).to(eq(challenge_step.title))
      expect(parsed_body["position"]).to(eq(challenge_step.position))
      expect(parsed_body["challenge_template_id"]).to(eq(challenge.id))
    end
  end

  context "when challenge is private" do
    let(:challenge) { create(:challenge, :private, creator: creator) }

    context "when user is not authorized" do
      before { do_request }

      it "returns 403 Forbidden" do
        expect(response).to(have_http_status(:forbidden))
      end
    end

    context "when user is the challenge creator" do
      let(:user) { creator }

      before { do_request }

      it "returns 200 OK" do
        expect(response).to(have_http_status(:ok))
      end
    end
  end

  context "when challenge step does not exist" do
    subject(:do_request) do
      get "/api/v1/challenges/#{challenge.id}/challenge_steps/999999", headers: auth_headers(user)
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    subject(:do_request) do
      get "/api/v1/challenges/#{challenge.id}/challenge_steps/#{challenge_step.id}", headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
