# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Groups::MemberAdder) do
  let(:admin) { create(:user, username: "admin_user") }
  let(:member) { create(:user, username: "regular_member") }
  let(:target_user) { create(:user, username: "target_user", email: "target@example.com") }
  let(:challenge) { create(:challenge, creator: admin) }
  let(:group) { create(:group, challenge: challenge, creator: admin) }
  let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }

  describe "#call" do
    context "when current_user is an admin" do
      context "adding a user by email" do
        subject(:result) do
          described_class.new(
            group: group,
            identifier: target_user.email,
            current_user: admin,
          ).call
        end

        it "creates a membership" do
          expect { result }.to(change(Membership, :count).by(1))
        end

        it "returns the membership" do
          expect(result).to(be_a(Membership))
          expect(result.user).to(eq(target_user))
          expect(result.group).to(eq(group))
        end

        it "sets role to member by default" do
          expect(result.role).to(eq("member"))
        end
      end

      context "adding a user by username" do
        subject(:result) do
          described_class.new(
            group: group,
            identifier: target_user.username,
            current_user: admin,
          ).call
        end

        it "creates a membership" do
          expect { result }.to(change(Membership, :count).by(1))
        end

        it "finds user case-insensitively" do
          result = described_class.new(
            group: group,
            identifier: target_user.username.upcase,
            current_user: admin,
          ).call

          expect(result.user).to(eq(target_user))
        end
      end

      context "adding a user as admin" do
        subject(:result) do
          described_class.new(
            group: group,
            identifier: target_user.email,
            current_user: admin,
            role: "admin",
          ).call
        end

        it "sets the specified role" do
          expect(result.role).to(eq("admin"))
        end
      end

      context "when user is not found" do
        it "raises UserNotFoundError" do
          expect {
            described_class.new(
              group: group,
              identifier: "nonexistent@example.com",
              current_user: admin,
            ).call
          }.to(raise_error(Groups::MemberAdder::UserNotFoundError, /User not found/))
        end
      end

      context "when user is already a member" do
        before { create(:membership, group: group, user: target_user) }

        it "raises AlreadyMemberError" do
          expect {
            described_class.new(
              group: group,
              identifier: target_user.email,
              current_user: admin,
            ).call
          }.to(raise_error(Groups::MemberAdder::AlreadyMemberError, /already a member/))
        end
      end

      context "when user has a discarded membership" do
        before do
          membership = create(:membership, group: group, user: target_user)
          membership.discard!
        end

        it "undiscards the membership" do
          result = described_class.new(
            group: group,
            identifier: target_user.email,
            current_user: admin,
          ).call

          expect(result).to(be_persisted)
          expect(result.discarded?).to(be(false))
        end
      end
    end

    context "when current_user is not an admin" do
      let!(:member_membership) { create(:membership, group: group, user: member, role: "member") }

      it "raises NotAuthorizedError" do
        expect {
          described_class.new(
            group: group,
            identifier: target_user.email,
            current_user: member,
          ).call
        }.to(raise_error(Groups::MemberAdder::NotAuthorizedError, /Only group admins/))
      end
    end

    context "when current_user is not a member at all" do
      let(:non_member) { create(:user) }

      it "raises NotAuthorizedError" do
        expect {
          described_class.new(
            group: group,
            identifier: target_user.email,
            current_user: non_member,
          ).call
        }.to(raise_error(Groups::MemberAdder::NotAuthorizedError, /Only group admins/))
      end
    end
  end
end
