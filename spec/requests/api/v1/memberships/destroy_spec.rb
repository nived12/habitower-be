# frozen_string_literal: true

require "rails_helper"

RSpec.describe("DELETE /api/v1/groups/:group_id/memberships/:id", type: :request) do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:other_member) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: admin) }
  let(:group) { create(:group, challenge_template: challenge_template, creator: admin) }
  let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }
  let!(:member_membership) { create(:membership, group: group, user: member, role: "member") }

  subject(:do_request) do
    delete "/api/v1/groups/#{group.id}/memberships/#{member_membership.id}",
      headers: auth_headers(current_user)
  end

  context "when current_user is an admin" do
    let(:current_user) { admin }

    it "returns 204 No Content" do
      do_request
      expect(response).to(have_http_status(:no_content))
    end

    it "soft deletes the membership" do
      expect { do_request }.to(change { member_membership.reload.discarded? }.from(false).to(true))
    end
  end

  context "when current_user is not an admin" do
    let!(:other_membership) { create(:membership, group: group, user: other_member, role: "member") }
    let(:current_user) { other_member }

    before { do_request }

    it "returns 403 Forbidden" do
      expect(response).to(have_http_status(:forbidden))
    end

    it "does not discard the membership" do
      expect(member_membership.reload.discarded?).to(be(false))
    end
  end

  context "when membership does not exist" do
    let(:current_user) { admin }

    subject(:do_request) do
      delete "/api/v1/groups/#{group.id}/memberships/999999",
        headers: auth_headers(current_user)
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    subject(:do_request) do
      delete "/api/v1/groups/#{group.id}/memberships/#{member_membership.id}",
        headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
