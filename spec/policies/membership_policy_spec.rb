# frozen_string_literal: true

require "rails_helper"

RSpec.describe(MembershipPolicy, type: :policy) do
  let(:creator) { create(:user) }
  let(:member) { create(:user) }
  let(:admin) { create(:user) }
  let(:other_user) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator) }
  let(:group) { create(:group, challenge_template: challenge_template, creator: creator) }

  describe "#destroy?" do
    context "when membership belongs to group creator" do
      let!(:creator_membership) { create(:membership, group: group, user: creator, role: "admin") }

      it "denies the creator (cannot leave)" do
        policy = described_class.new(creator, creator_membership)
        expect(policy.destroy?).to(be(false))
      end
    end

    context "when membership belongs to a regular member" do
      let!(:member_membership) { create(:membership, group: group, user: member, role: "member") }

      it "permits the member to leave" do
        policy = described_class.new(member, member_membership)
        expect(policy.destroy?).to(be(true))
      end

      context "when current user is a group admin" do
        let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }

        it "permits removing the member" do
          policy = described_class.new(admin, member_membership)
          expect(policy.destroy?).to(be(true))
        end
      end

      context "when current user is another member (not admin)" do
        let!(:other_membership) { create(:membership, group: group, user: other_user, role: "member") }

        it "denies removing the member" do
          policy = described_class.new(other_user, member_membership)
          expect(policy.destroy?).to(be(false))
        end
      end
    end
  end
end
