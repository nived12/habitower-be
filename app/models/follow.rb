# frozen_string_literal: true

class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :cannot_follow_self

  private

  def cannot_follow_self
    return unless follower_id.present? && followed_id.present?
    return unless follower_id == followed_id

    errors.add(:followed_id, "cannot follow yourself")
  end
end

# == Schema Information
#
# Table name: follows
#
#  id                   :integer            not null, primary key
#  follower_id          :integer            not null
#  followed_id          :integer            not null
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#
# Indexes
#
#  index_follows_on_followed_id (followed_id)
#  index_follows_on_follower_id (follower_id)
#  index_follows_on_follower_id_and_followed_id (follower_id,followed_id) UNIQUE
#
