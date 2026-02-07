# frozen_string_literal: true

module Groups
  class MemberAdder < ApplicationService
    attr_reader :group, :identifier, :current_user, :role

    def initialize(group:, identifier:, current_user:, role: "member")
      super()
      @group = group
      @identifier = identifier
      @current_user = current_user
      @role = role
    end

    def call
      return failure("Only group admins can add members", http_status: :forbidden) unless admin?

      user = find_user
      return failure("User not found with identifier: #{identifier}", http_status: :not_found) if user.nil?
      return failure("User is already a member of this group") if already_member?(user)

      membership = create_membership(user)
      success(membership)
    end

    private

    def admin?
      group.memberships.kept.exists?(user_id: current_user.id, role: "admin")
    end

    def find_user
      User.by_email_or_username(identifier).first
    end

    def already_member?(user)
      group.memberships.kept.exists?(user_id: user.id)
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
