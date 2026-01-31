# frozen_string_literal: true

class GroupPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    visible?
  end

  def create?
    true
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  def join?
    # Let the service handle "already member" validation with a proper error message
    true
  end

  def leave?
    member? && !owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.left_joins(:memberships)
        .where(privacy_type: "public")
        .or(scope.where(creator_id: user.id))
        .or(scope.where(memberships: { user_id: user.id }))
        .distinct
    end
  end

  private

  def owner?
    record.creator_id == user.id
  end

  def member?
    record.memberships.kept.exists?(user_id: user.id)
  end

  def visible?
    record.privacy_type_public? || owner? || member?
  end
end
