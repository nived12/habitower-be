# frozen_string_literal: true

module Groups
  class Joiner < ApplicationService
    attr_reader :group, :user, :invite_code

    def initialize(group:, user:, invite_code: nil)
      super()
      @group = group
      @user = user
      @invite_code = invite_code
    end

    def call
      return failure("User is already a member of this group") if already_member?
      return failure("Invalid invite code", http_status: :forbidden) if private_group? && !valid_invite_code?

      membership = find_or_create_membership
      success(membership)
    end

    private

    def already_member?
      group.memberships.kept.exists?(user_id: user.id)
    end

    def private_group?
      group.privacy_type_private?
    end

    def valid_invite_code?
      invite_code.present? && invite_code.upcase == group.invite_code&.upcase
    end

    def find_or_create_membership
      existing_membership = group.memberships.discarded.find_by(user_id: user.id)

      if existing_membership
        existing_membership.undiscard!
        existing_membership
      else
        Membership.create!(
          group: group,
          user: user,
          role: "member"
        )
      end
    end
  end
end
