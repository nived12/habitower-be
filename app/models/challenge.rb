# frozen_string_literal: true

class Challenge < ApplicationRecord
  include Discard::Model

  validates :title, presence: true

  enum :period_type, { weekly: "weekly", monthly: "monthly" }, default: :weekly, validate: true

  belongs_to :creator, class_name: "User"
  has_many :challenge_steps, dependent: :destroy
  has_many :groups, dependent: :destroy

  after_discard { challenge_steps.discard_all; groups.discard_all }
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
#
# Indexes
#
#  index_challenges_on_creator_id (creator_id)
#  index_challenges_on_discarded_at (discarded_at)
#
