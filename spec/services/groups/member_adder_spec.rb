# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Groups::MemberAdder) do
  let(:admin) { create(:user, username: "admin_user") }
  let(:member) { create(:user, username: "regular_member") }
  let(:target_user) { create(:user, username: "target_user", email: "target@example.com") }
  let(:challenge_template) { create(:challenge_template, creator: admin) }
  let(:group) { create(:group, challenge_template: challenge_template, creator: admin) }
  let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }

  describe "#call" do
    context "when current_user is an admin" do
      context "adding a user by email" do
        subject(:result) do
          described_class.call(
            group: group,
            identifier: target_user.email,
            current_user: admin
          )
        end

        it "creates a membership" do
          expect { result }.to(change(Membership, :count).by(1))
        end

        it "returns success with membership payload" do
          expect(result.success?).to(be(true))
          expect(result.payload).to(be_a(Membership))
          expect(result.payload.user).to(eq(target_user))
          expect(result.payload.group).to(eq(group))
        end

        it "sets role to member by default" do
          expect(result.payload.role).to(eq("member"))
        end
      end

      context "adding a user by username" do
        subject(:result) do
          described_class.call(
            group: group,
            identifier: target_user.username,
            current_user: admin
          )
        end

        it "creates a membership" do
          expect { result }.to(change(Membership, :count).by(1))
        end

        it "finds user case-insensitively" do
          result = described_class.call(
            group: group,
            identifier: target_user.username.upcase,
            current_user: admin
          )

          expect(result.payload.user).to(eq(target_user))
        end
      end

      context "adding a user as admin" do
        subject(:result) do
          described_class.call(
            group: group,
            identifier: target_user.email,
            current_user: admin,
            role: "admin"
          )
        end

        it "sets the specified role" do
          expect(result.payload.role).to(eq("admin"))
        end
      end

      context "when user is not found" do
        it "returns failure" do
          result = described_class.call(
            group: group,
            identifier: "nonexistent@example.com",
            current_user: admin
          )

          expect(result.failure?).to(be(true))
          expect(result.errors.full_messages.first).to(include("User not found"))
        end
      end

      context "when user is already a member" do
        before { create(:membership, group: group, user: target_user) }

        it "returns failure" do
          result = described_class.call(
            group: group,
            identifier: target_user.email,
            current_user: admin
          )

          expect(result.failure?).to(be(true))
          expect(result.errors.full_messages.first).to(include("already a member"))
        end
      end

      context "when user has a discarded membership" do
        before do
          membership = create(:membership, group: group, user: target_user)
          membership.discard!
        end

        it "undiscards the membership" do
          result = described_class.call(
            group: group,
            identifier: target_user.email,
            current_user: admin
          )

          expect(result.success?).to(be(true))
          expect(result.payload.discarded?).to(be(false))
        end
      end
    end

    context "when current_user is not an admin" do
      let!(:member_membership) { create(:membership, group: group, user: member, role: "member") }

      it "returns failure" do
        result = described_class.call(
          group: group,
          identifier: target_user.email,
          current_user: member
        )

        expect(result.failure?).to(be(true))
        expect(result.errors.full_messages.first).to(include("Only group admins"))
      end
    end

    context "when current_user is not a member at all" do
      let(:non_member) { create(:user) }

      it "returns failure" do
        result = described_class.call(
          group: group,
          identifier: target_user.email,
          current_user: non_member
        )

        expect(result.failure?).to(be(true))
        expect(result.errors.full_messages.first).to(include("Only group admins"))
      end
    end
  end
end
