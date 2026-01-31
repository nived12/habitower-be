# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ChallengeStepPolicy, type: :policy) do
  let(:creator) { create(:user) }
  let(:other_user) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }
  let(:challenge_step) { create(:challenge_step, challenge: challenge, creator: creator) }

  describe "#index?" do
    context "when challenge is public" do
      it "permits any authenticated user" do
        policy = described_class.new(other_user, challenge_step)
        expect(policy.index?).to(be(true))
      end
    end

    context "when challenge is private" do
      let(:challenge) { create(:challenge, :private, creator: creator) }

      it "permits the challenge creator" do
        policy = described_class.new(creator, challenge_step)
        expect(policy.index?).to(be(true))
      end

      it "denies a non-member user" do
        policy = described_class.new(other_user, challenge_step)
        expect(policy.index?).to(be(false))
      end

      context "when user is a member of a group using the challenge" do
        let(:group) { create(:group, challenge: challenge, creator: creator) }
        let!(:membership) { create(:membership, group: group, user: other_user) }

        it "permits the member" do
          policy = described_class.new(other_user, challenge_step)
          expect(policy.index?).to(be(true))
        end
      end
    end
  end

  describe "#show?" do
    context "when challenge is public" do
      it "permits any authenticated user" do
        policy = described_class.new(other_user, challenge_step)
        expect(policy.show?).to(be(true))
      end
    end

    context "when challenge is private" do
      let(:challenge) { create(:challenge, :private, creator: creator) }

      it "permits the challenge creator" do
        policy = described_class.new(creator, challenge_step)
        expect(policy.show?).to(be(true))
      end

      it "denies a non-member user" do
        policy = described_class.new(other_user, challenge_step)
        expect(policy.show?).to(be(false))
      end
    end
  end

  describe "#create?" do
    context "when user is the challenge creator" do
      it "permits the action" do
        new_step = challenge.challenge_steps.build(title: "New Step", position: 1, creator: creator)
        policy = described_class.new(creator, new_step)
        expect(policy.create?).to(be(true))
      end
    end

    context "when user is not the challenge creator" do
      it "denies the action" do
        new_step = challenge.challenge_steps.build(title: "New Step", position: 1, creator: other_user)
        policy = described_class.new(other_user, new_step)
        expect(policy.create?).to(be(false))
      end
    end
  end

  describe "#update?" do
    context "when user is the challenge creator" do
      it "permits the action" do
        policy = described_class.new(creator, challenge_step)
        expect(policy.update?).to(be(true))
      end
    end

    context "when user is not the challenge creator" do
      it "denies the action" do
        policy = described_class.new(other_user, challenge_step)
        expect(policy.update?).to(be(false))
      end
    end
  end

  describe "#destroy?" do
    context "when user is the challenge creator" do
      it "permits the action" do
        policy = described_class.new(creator, challenge_step)
        expect(policy.destroy?).to(be(true))
      end
    end

    context "when user is not the challenge creator" do
      it "denies the action" do
        policy = described_class.new(other_user, challenge_step)
        expect(policy.destroy?).to(be(false))
      end
    end
  end
end
