# frozen_string_literal: true

require "rails_helper"

RSpec.describe("PATCH /api/v1/challenges/:id", type: :request) do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  subject(:do_request) do
    patch "/api/v1/challenges/#{challenge.id}", params: request_params.to_json, headers: auth_headers(user)
  end

  context "when user is the creator" do
    let(:challenge) { create(:challenge, creator: user, title: "Original Title") }

    context "with valid params" do
      let(:request_params) { { challenge: { title: "Updated Title" } } }

      before { do_request }

      it "returns 200 OK" do
        expect(response).to(have_http_status(:ok))
      end

      it "updates the challenge" do
        expect(challenge.reload.title).to(eq("Updated Title"))
      end

      it "returns the updated challenge" do
        expect(parsed_body["title"]).to(eq("Updated Title"))
      end
    end

    context "with invalid params" do
      let(:request_params) { { challenge: { title: "" } } }

      before { do_request }

      it "returns 422 Unprocessable Entity" do
        expect(response).to(have_http_status(:unprocessable_content))
      end
    end

    context "with category_ids" do
      let(:category) { create(:category, name: "Fitness", slug: "fitness") }
      let(:request_params) { { challenge: { category_ids: [category.id] } } }

      before { do_request }

      it "updates the challenge categories" do
        expect(challenge.reload.categories).to(include(category))
        expect(parsed_body["categories"].size).to(eq(1))
        expect(parsed_body["categories"].first["slug"]).to(eq("fitness"))
      end
    end
  end

  context "when user is not the creator" do
    let(:challenge) { create(:challenge, creator: other_user) }
    let(:request_params) { { challenge: { title: "Hacked Title" } } }

    before { do_request }

    it "returns 403 Forbidden" do
      expect(response).to(have_http_status(:forbidden))
    end

    it "does not update the challenge" do
      expect(challenge.reload.title).not_to(eq("Hacked Title"))
    end
  end

  context "when challenge does not exist" do
    let(:request_params) { { challenge: { title: "Test" } } }

    subject(:do_request) do
      patch "/api/v1/challenges/999999", params: request_params.to_json, headers: auth_headers(user)
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    let(:challenge) { create(:challenge, creator: user) }
    let(:request_params) { { challenge: { title: "Test" } } }

    subject(:do_request) do
      patch "/api/v1/challenges/#{challenge.id}", params: request_params.to_json, headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
