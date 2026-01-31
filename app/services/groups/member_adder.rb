# frozen_string_literal: true

module Groups
  class MemberAdder
    class UserNotFoundError < StandardError; end
    class AlreadyMemberError < StandardError; end
    class NotAuthorizedError < StandardError; end

    attr_reader :group, :identifier, :current_user, :role

    def initialize(group:, identifier:, current_user:, role: "member")
      @group = group
      @identifier = identifier
      @current_user = current_user
      @role = role
    end

    def call
      validate_authorization!
      user = find_user!
      validate_not_already_member!(user)

      create_membership(user)
    end

    private

    def validate_authorization!
      return if admin?

      raise(NotAuthorizedError, "Only group admins can add members")
    end

    def admin?
      group.memberships.kept.exists?(user_id: current_user.id, role: "admin")
    end

    def find_user!
      user = User.by_email_or_username(identifier).first
      raise(UserNotFoundError, "User not found with identifier: #{identifier}") unless user

      user
    end

    def validate_not_already_member!(user)
      return unless group.memberships.kept.exists?(user_id: user.id)

      raise(AlreadyMemberError, "User is already a member of this group")
    end

    def create_membership(user)
      existing_discarded = group.memberships.discarded.find_by(user_id: user.id)

      if existing_discarded
        existing_discarded.update!(role: role)
        existing_discarded.undiscard!
        existing_discarded
      else
        Membership.create!(
          group: group,
          user: user,
          role: role,
        )
      end
    end
  end
end
