# frozen_string_literal: true

class MembershipPolicy < ApplicationPolicy
  def destroy?
    return false if creator_leaving? # group creator cannot leave
    return true if record.user_id == user.id # member leaving self

    admin_of_group?
  end

  private

  def creator_leaving?
    record.user_id == user.id && record.group.creator_id == user.id
  end

  def admin_of_group?
    record.group.memberships.kept.exists?(user_id: user.id, role: "admin")
  end
end
