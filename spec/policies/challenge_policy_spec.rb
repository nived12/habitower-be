# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ChallengePolicy, type: :policy) do
  let(:creator) { create(:user) }
  let(:other_user) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }

  describe "#index?" do
    it "permits any authenticated user" do
      policy = described_class.new(other_user, Challenge)
      expect(policy.index?).to(be(true))
    end
  end

  describe "#show?" do
    context "when challenge is public" do
      it "permits any authenticated user" do
        policy = described_class.new(other_user, challenge)
        expect(policy.show?).to(be(true))
      end
    end

    context "when challenge is private" do
      let(:private_challenge) { create(:challenge, :private, creator: creator) }

      it "permits the creator" do
        policy = described_class.new(creator, private_challenge)
        expect(policy.show?).to(be(true))
      end

      it "denies a non-member user" do
        policy = described_class.new(other_user, private_challenge)
        expect(policy.show?).to(be(false))
      end

      context "when user is a member of a group using the challenge" do
        let(:group) { create(:group, challenge: private_challenge, creator: creator) }
        let!(:membership) { create(:membership, group: group, user: other_user) }

        it "permits the member" do
          policy = described_class.new(other_user, private_challenge)
          expect(policy.show?).to(be(true))
        end
      end
    end
  end

  describe "#create?" do
    it "permits any authenticated user" do
      policy = described_class.new(other_user, Challenge.new)
      expect(policy.create?).to(be(true))
    end
  end

  describe "#update?" do
    context "when user is the creator" do
      it "permits the action" do
        policy = described_class.new(creator, challenge)
        expect(policy.update?).to(be(true))
      end
    end

    context "when user is not the creator" do
      it "denies the action" do
        policy = described_class.new(other_user, challenge)
        expect(policy.update?).to(be(false))
      end
    end
  end

  describe "#destroy?" do
    context "when user is the creator" do
      it "permits the action" do
        policy = described_class.new(creator, challenge)
        expect(policy.destroy?).to(be(true))
      end
    end

    context "when user is not the creator" do
      it "denies the action" do
        policy = described_class.new(other_user, challenge)
        expect(policy.destroy?).to(be(false))
      end
    end
  end

  describe "Scope" do
    let!(:public_challenge) { create(:challenge, creator: creator) }
    let!(:private_challenge) { create(:challenge, :private, creator: creator) }
    let!(:other_private_challenge) { create(:challenge, :private, creator: other_user) }

    it "includes public challenges" do
      scope = described_class::Scope.new(other_user, Challenge.kept).resolve
      expect(scope).to(include(public_challenge))
    end

    it "includes private challenges created by the user" do
      scope = described_class::Scope.new(creator, Challenge.kept).resolve
      expect(scope).to(include(private_challenge))
    end

    it "excludes private challenges the user cannot access" do
      scope = described_class::Scope.new(creator, Challenge.kept).resolve
      expect(scope).not_to(include(other_private_challenge))
    end

    context "when user is a member of a group using a private challenge" do
      let(:group) { create(:group, challenge: other_private_challenge, creator: other_user) }
      let!(:membership) { create(:membership, group: group, user: creator) }

      it "includes the private challenge" do
        scope = described_class::Scope.new(creator, Challenge.kept).resolve
        expect(scope).to(include(other_private_challenge))
      end
    end
  end
end
