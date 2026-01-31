# frozen_string_literal: true

require "rails_helper"

RSpec.describe("DELETE /api/v1/groups/:id", type: :request) do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: user) }

  subject(:do_request) do
    delete "/api/v1/groups/#{group.id}", headers: auth_headers(user)
  end

  context "when user is the creator" do
    let!(:group) { create(:group, challenge_template: challenge_template, creator: user) }

    it "returns 204 No Content" do
      do_request
      expect(response).to(have_http_status(:no_content))
    end

    it "soft deletes the group" do
      expect { do_request }.to(change { group.reload.discarded? }.from(false).to(true))
    end

    it "does not permanently delete the group" do
      expect { do_request }.not_to(change(Group.unscoped, :count))
    end
  end

  context "when user is not the creator" do
    let!(:group) { create(:group, challenge_template: challenge_template, creator: other_user) }

    before { do_request }

    it "returns 403 Forbidden" do
      expect(response).to(have_http_status(:forbidden))
    end

    it "does not discard the group" do
      expect(group.reload.discarded?).to(be(false))
    end
  end

  context "when group does not exist" do
    subject(:do_request) do
      delete "/api/v1/groups/999999", headers: auth_headers(user)
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    let!(:group) { create(:group, challenge_template: challenge_template, creator: user) }

    subject(:do_request) do
      delete "/api/v1/groups/#{group.id}", headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
