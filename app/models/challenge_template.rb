# frozen_string_literal: true

class ChallengeTemplate < ApplicationRecord
  include Discard::Model

  validates :title, presence: true

  enum :period_type, { weekly: "weekly", monthly: "monthly" }, default: :weekly, validate: true
  enum :privacy_type, { public: "public", private: "private" }, default: :public, validate: true, prefix: true

  belongs_to :creator, class_name: "User"
  has_many :challenge_step_templates, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :memberships, through: :groups
  has_many :members, through: :memberships, source: :user
  has_many :challenge_template_categories, dependent: :destroy
  has_many :categories, through: :challenge_template_categories

  after_discard { challenge_step_templates.discard_all; groups.discard_all }

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
# Table name: challenge_templates
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
#  index_challenge_templates_on_creator_id (creator_id)
#  index_challenge_templates_on_discarded_at (discarded_at)
#  index_challenge_templates_on_privacy_type (privacy_type)
#
