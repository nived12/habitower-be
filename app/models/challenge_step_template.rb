# frozen_string_literal: true

class ChallengeStepTemplate < ApplicationRecord
  include Discard::Model

  validates :title, :position, presence: true

  belongs_to :challenge_template
  belongs_to :creator, class_name: "User"
  has_many :group_steps, foreign_key: :original_step_id, dependent: :nullify
end

# == Schema Information
#
# Table name: challenge_step_templates
#
#  id                   :integer            not null, primary key
#  challenge_template_id :integer            not null
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
#  index_challenge_step_templates_on_challenge_template_id (challenge_template_id)
#  index_challenge_step_templates_on_creator_id (creator_id)
#  index_challenge_step_templates_on_discarded_at (discarded_at)
#
