# frozen_string_literal: true

class ProgressLog < ApplicationRecord
  include Discard::Model

  validates :value, :occurred_at, presence: true

  belongs_to :membership
  belongs_to :group_step
  has_many :reactions, dependent: :destroy
end

# == Schema Information
#
# Table name: progress_logs
#
#  id                   :integer            not null, primary key
#  membership_id        :integer            not null
#  value                :numeric(15,4)      not null
#  occurred_at          :timestamp(6) without time zone not null
#  note                 :text               null
#  proof_url            :string             null
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#  discarded_at         :timestamp(6) without time zone null
#  group_step_id        :integer            not null
#
# Indexes
#
#  index_progress_logs_on_discarded_at (discarded_at)
#  index_progress_logs_on_group_step_id (group_step_id)
#  index_progress_logs_on_membership_id (membership_id)
#
