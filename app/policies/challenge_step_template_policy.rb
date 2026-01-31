# frozen_string_literal: true

class ChallengeStepTemplatePolicy < ApplicationPolicy
  def index?
    challenge_visible?
  end

  def show?
    challenge_visible?
  end

  def create?
    challenge_owner?
  end

  def update?
    challenge_owner?
  end

  def destroy?
    challenge_owner?
  end

  private

  def challenge
    record.challenge_template
  end

  def challenge_owner?
    challenge.creator_id == user.id
  end

  def challenge_visible?
    challenge.privacy_type_public? || challenge_owner? || member_of_challenge_group?
  end

  def member_of_challenge_group?
    challenge.memberships.exists?(user_id: user.id)
  end
end
