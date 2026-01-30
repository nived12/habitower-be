# frozen_string_literal: true

class ChallengeStep < ApplicationRecord
  include Discard::Model

  validates :title, :position, presence: true

  belongs_to :challenge
  belongs_to :creator, class_name: "User"
  has_many :progress_logs, dependent: :destroy

  after_discard { progress_logs.discard_all }
end

# == Schema Information
#
# Table name: challenge_steps
#
#  id                   :integer            not null, primary key
#  challenge_id         :integer            not null
#  creator_id           :integer            not null
#  title                :string             not null
#  position             :integer            not null
#  requirements         :jsonb              not null, default("{}")
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#  discarded_at         :timestamp(6) without time zone null
#
# Indexes
#
#  index_challenge_steps_on_challenge_id (challenge_id)
#  index_challenge_steps_on_creator_id (creator_id)
#  index_challenge_steps_on_discarded_at (discarded_at)
#
