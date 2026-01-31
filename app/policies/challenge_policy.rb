# frozen_string_literal: true

class ChallengePolicy < ApplicationPolicy
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

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.visible_to(user)
    end
  end

  private

  def owner?
    record.creator_id == user.id
  end

  def visible?
    record.privacy_type_public? || owner? || member_of_challenge_group?
  end

  def member_of_challenge_group?
    record.memberships.exists?(user_id: user.id)
  end
end
