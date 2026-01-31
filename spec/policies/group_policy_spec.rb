# frozen_string_literal: true

require "rails_helper"

RSpec.describe(GroupPolicy, type: :policy) do
  let(:creator) { create(:user) }
  let(:member_user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }
  let(:group) { create(:group, challenge: challenge, creator: creator) }
  let!(:membership) { create(:membership, group: group, user: member_user) }

  describe "#index?" do
    it "permits any authenticated user" do
      policy = described_class.new(other_user, Group)
      expect(policy.index?).to(be(true))
    end
  end

  describe "#show?" do
    context "when group is public" do
      it "permits any authenticated user" do
        policy = described_class.new(other_user, group)
        expect(policy.show?).to(be(true))
      end
    end

    context "when group is private" do
      let(:group) { create(:group, challenge: challenge, creator: creator, privacy_type: "private") }

      it "permits the creator" do
        policy = described_class.new(creator, group)
        expect(policy.show?).to(be(true))
      end

      it "permits members" do
        policy = described_class.new(member_user, group)
        expect(policy.show?).to(be(true))
      end

      it "denies non-members" do
        policy = described_class.new(other_user, group)
        expect(policy.show?).to(be(false))
      end
    end
  end

  describe "#create?" do
    it "permits any authenticated user" do
      policy = described_class.new(other_user, Group.new)
      expect(policy.create?).to(be(true))
    end
  end

  describe "#update?" do
    context "when user is the creator" do
      it "permits the action" do
        policy = described_class.new(creator, group)
        expect(policy.update?).to(be(true))
      end
    end

    context "when user is not the creator" do
      it "denies the action for members" do
        policy = described_class.new(member_user, group)
        expect(policy.update?).to(be(false))
      end

      it "denies the action for non-members" do
        policy = described_class.new(other_user, group)
        expect(policy.update?).to(be(false))
      end
    end
  end

  describe "#destroy?" do
    context "when user is the creator" do
      it "permits the action" do
        policy = described_class.new(creator, group)
        expect(policy.destroy?).to(be(true))
      end
    end

    context "when user is not the creator" do
      it "denies the action" do
        policy = described_class.new(member_user, group)
        expect(policy.destroy?).to(be(false))
      end
    end
  end

  describe "#join?" do
    # Note: Pundit allows the join attempt; the service validates membership
    context "when user is not a member" do
      it "permits the action" do
        policy = described_class.new(other_user, group)
        expect(policy.join?).to(be(true))
      end
    end

    context "when user is already a member" do
      it "permits the action (service handles validation)" do
        policy = described_class.new(member_user, group)
        expect(policy.join?).to(be(true))
      end
    end
  end

  describe "#leave?" do
    context "when user is a member but not the creator" do
      it "permits the action" do
        policy = described_class.new(member_user, group)
        expect(policy.leave?).to(be(true))
      end
    end

    context "when user is the creator" do
      let!(:creator_membership) { create(:membership, group: group, user: creator, role: "admin") }

      it "denies the action" do
        policy = described_class.new(creator, group)
        expect(policy.leave?).to(be(false))
      end
    end

    context "when user is not a member" do
      it "denies the action" do
        policy = described_class.new(other_user, group)
        expect(policy.leave?).to(be(false))
      end
    end
  end

  describe "Scope" do
    let!(:public_group) { create(:group, challenge: challenge, creator: creator) }
    let!(:private_group) { create(:group, challenge: challenge, creator: creator, privacy_type: "private") }
    let!(:other_private_group) { create(:group, challenge: challenge, creator: other_user, privacy_type: "private") }

    it "includes public groups" do
      scope = described_class::Scope.new(other_user, Group.kept).resolve
      expect(scope).to(include(public_group))
    end

    it "includes private groups created by the user" do
      scope = described_class::Scope.new(creator, Group.kept).resolve
      expect(scope).to(include(private_group))
    end

    it "excludes private groups the user cannot access" do
      scope = described_class::Scope.new(creator, Group.kept).resolve
      expect(scope).not_to(include(other_private_group))
    end

    context "when user is a member of a private group" do
      let!(:private_membership) { create(:membership, group: other_private_group, user: creator) }

      it "includes the private group" do
        scope = described_class::Scope.new(creator, Group.kept).resolve
        expect(scope).to(include(other_private_group))
      end
    end
  end
end
