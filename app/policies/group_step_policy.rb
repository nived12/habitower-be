# frozen_string_literal: true

class GroupStepPolicy < ApplicationPolicy
  def index?
    member?
  end

  def show?
    member?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  private

  def membership
    @membership ||= record.group.memberships.kept.find_by(user_id: user.id)
  end

  def member?
    membership.present?
  end

  def admin?
    membership&.admin?
  end
end
