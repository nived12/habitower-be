# frozen_string_literal: true

require "rails_helper"

RSpec.describe("DELETE /api/v1/challenges/:challenge_id/challenge_steps/:id", type: :request) do
  let(:creator) { create(:user) }
  let(:other_user) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }
  let!(:challenge_step) { create(:challenge_step, challenge_template: challenge, creator: creator) }

  subject(:do_request) do
    delete "/api/v1/challenges/#{challenge.id}/challenge_steps/#{challenge_step.id}",
      headers: auth_headers(user)
  end

  context "when user is the challenge creator" do
    let(:user) { creator }

    it "returns 204 No Content" do
      do_request
      expect(response).to(have_http_status(:no_content))
    end

    it "soft deletes the challenge step" do
      expect { do_request }.to(change { challenge_step.reload.discarded? }.from(false).to(true))
    end

    it "does not permanently delete the challenge step" do
      expect { do_request }.not_to(change(ChallengeStepTemplate.unscoped, :count))
    end
  end

  context "when user is not the challenge creator" do
    let(:user) { other_user }

    before { do_request }

    it "returns 403 Forbidden" do
      expect(response).to(have_http_status(:forbidden))
    end

    it "does not discard the challenge step" do
      expect(challenge_step.reload.discarded?).to(be(false))
    end
  end

  context "when challenge step does not exist" do
    let(:user) { creator }

    subject(:do_request) do
      delete "/api/v1/challenges/#{challenge.id}/challenge_steps/999999",
        headers: auth_headers(user)
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    subject(:do_request) do
      delete "/api/v1/challenges/#{challenge.id}/challenge_steps/#{challenge_step.id}",
        headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
