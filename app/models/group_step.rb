# frozen_string_literal: true

class GroupStep < ApplicationRecord
  include Discard::Model

  validates :title, :position, presence: true

  belongs_to :group
  belongs_to :creator, class_name: "User"
  belongs_to :original_step, class_name: "ChallengeStepTemplate", optional: true
  has_many :progress_logs, dependent: :destroy

  after_discard { progress_logs.discard_all }
end

# == Schema Information
#
# Table name: group_steps
#
#  id                   :integer            not null, primary key
#  group_id             :integer            not null
#  creator_id           :integer            not null
#  title                :string             not null
#  position             :integer            not null
#  requirements         :jsonb              not null, default("{}")
#  original_step_id     :integer            null
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#  discarded_at         :timestamp(6) without time zone null
#
# Indexes
#
#  index_group_steps_on_creator_id (creator_id)
#  index_group_steps_on_discarded_at (discarded_at)
#  index_group_steps_on_group_id (group_id)
#  index_group_steps_on_group_id_and_position (group_id,position)
#  index_group_steps_on_original_step_id (original_step_id)
#
