# frozen_string_literal: true

require "rails_helper"

RSpec.describe("PATCH /api/v1/groups/:id", type: :request) do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: user) }

  subject(:do_request) do
    patch "/api/v1/groups/#{group.id}", params: request_params.to_json, headers: auth_headers(user)
  end

  context "when user is the creator" do
    let(:group) { create(:group, challenge_template: challenge_template, creator: user, privacy_type: "public") }

    context "with valid params" do
      let(:request_params) { { group: { privacy_type: "private" } } }

      before { do_request }

      it "returns 200 OK" do
        expect(response).to(have_http_status(:ok))
      end

      it "updates the group" do
        expect(group.reload.privacy_type).to(eq("private"))
      end
    end
  end

  context "when user is not the creator" do
    let(:group) { create(:group, challenge_template: challenge_template, creator: other_user) }
    let(:request_params) { { group: { privacy_type: "private" } } }

    before { do_request }

    it "returns 403 Forbidden" do
      expect(response).to(have_http_status(:forbidden))
    end

    it "does not update the group" do
      expect(group.reload.privacy_type).to(eq("public"))
    end
  end

  context "when group does not exist" do
    let(:request_params) { { group: { privacy_type: "private" } } }

    subject(:do_request) do
      patch "/api/v1/groups/999999", params: request_params.to_json, headers: auth_headers(user)
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    let(:group) { create(:group, challenge_template: challenge_template, creator: user) }
    let(:request_params) { { group: { privacy_type: "private" } } }

    subject(:do_request) do
      patch "/api/v1/groups/#{group.id}", params: request_params.to_json, headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
