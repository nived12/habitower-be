# frozen_string_literal: true

class Challenge < ApplicationRecord
  include Discard::Model

  validates :title, presence: true

  enum :period_type, { weekly: "weekly", monthly: "monthly" }, default: :weekly, validate: true
  enum :privacy_type, { public: "public", private: "private" }, default: :public, validate: true, prefix: true

  belongs_to :creator, class_name: "User"
  has_many :challenge_steps, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :memberships, through: :groups
  has_many :members, through: :memberships, source: :user

  after_discard { challenge_steps.discard_all; groups.discard_all }

  scope :visible_to, ->(user) {
    left_joins(:memberships)
      .where(privacy_type: "public")
      .or(where(creator_id: user.id))
      .or(where(memberships: { user_id: user.id }))
      .distinct
  }
end

# == Schema Information
#
# Table name: challenges
#
#  id                   :integer            not null, primary key
#  title                :string             not null
#  description          :text               null
#  period_type          :string             not null, default("weekly")
#  rules                :jsonb              not null, default("{}")
#  creator_id           :integer            not null
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#  discarded_at         :timestamp(6) without time zone null
#  privacy_type         :string             not null, default("public")
#
# Indexes
#
#  index_challenges_on_creator_id (creator_id)
#  index_challenges_on_discarded_at (discarded_at)
#  index_challenges_on_privacy_type (privacy_type)
#
