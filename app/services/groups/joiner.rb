# frozen_string_literal: true

module Groups
  class Joiner
    class AlreadyMemberError < StandardError; end
    class InvalidInviteCodeError < StandardError; end

    attr_reader :group, :user, :invite_code

    def initialize(group:, user:, invite_code: nil)
      @group = group
      @user = user
      @invite_code = invite_code
    end

    def call
      validate_not_already_member!
      validate_invite_code! if group.privacy_type_private?

      find_or_create_membership
    end

    private

    def validate_not_already_member!
      return unless group.memberships.kept.exists?(user_id: user.id)

      raise(AlreadyMemberError, "User is already a member of this group")
    end

    def validate_invite_code!
      return if invite_code.present? && invite_code.upcase == group.invite_code&.upcase

      raise(InvalidInviteCodeError, "Invalid invite code")
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
          role: "member",
        )
      end
    end
  end
end
