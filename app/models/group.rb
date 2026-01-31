# frozen_string_literal: true

class Group < ApplicationRecord
  include Discard::Model

  validates :start_date, presence: true
  validates :invite_code, uniqueness: true, allow_nil: true

  enum :privacy_type, { public: "public", private: "private" }, default: :public, validate: true, prefix: true

  belongs_to :challenge
  belongs_to :creator, class_name: "User"
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  after_discard { memberships.discard_all }

  scope :publicly_joinable, -> { where(privacy_type: "public") }

  def current_week
    return 0 if start_date > Date.current

    weeks_elapsed = ((Date.current - start_date).to_i / 7) + 1
    weeks_elapsed
  end

  def current_period
    return 0 if start_date > Date.current

    if challenge.weekly?
      current_week
    else
      months_elapsed = ((Date.current.year * 12 + Date.current.month) -
                        (start_date.year * 12 + start_date.month)) + 1
      months_elapsed
    end
  end
end

# == Schema Information
#
# Table name: groups
#
#  id                   :integer            not null, primary key
#  challenge_id         :integer            not null
#  creator_id           :integer            not null
#  start_date           :date               not null
#  privacy_type         :string             not null, default("public")
#  invite_code          :string             null
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#  discarded_at         :timestamp(6) without time zone null
#
# Indexes
#
#  index_groups_on_challenge_id (challenge_id)
#  index_groups_on_creator_id (creator_id)
#  index_groups_on_discarded_at (discarded_at)
#  index_groups_on_invite_code (invite_code)
#
