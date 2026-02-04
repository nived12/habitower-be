# frozen_string_literal: true

class Reaction < ApplicationRecord
  belongs_to :user
  belongs_to :progress_log

  enum :kind, { high_five: "high_five", nudge: "nudge" }, default: :high_five, validate: true

  validates :user_id, uniqueness: { scope: [:progress_log_id, :kind] }

  after_create :notify_log_owner

  private

  def notify_log_owner
    owner = progress_log.membership.user
    return if user_id == owner.id

    Notifications::Creator.call(
      recipient: owner,
      actor: user,
      action: kind,
      notifiable: progress_log,
      data: {}
    )
  end
end

# == Schema Information
#
# Table name: reactions
#
#  id                   :integer            not null, primary key
#  user_id              :integer            not null
#  progress_log_id      :integer            not null
#  kind                 :string             not null, default("high_five")
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#
# Indexes
#
#  index_reactions_on_progress_log_id (progress_log_id)
#  index_reactions_on_user_id (user_id)
#  index_reactions_on_user_id_and_progress_log_id_and_kind (user_id,progress_log_id,kind) UNIQUE
#
