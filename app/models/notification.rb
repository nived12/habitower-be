# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :action, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :for_recipient, ->(user) { where(recipient_id: user.id) }
end

# == Schema Information
#
# Table name: notifications
#
#  id                   :integer            not null, primary key
#  recipient_id         :integer            not null
#  actor_id             :integer            null
#  action               :string             not null
#  notifiable_type      :string             null
#  notifiable_id        :integer            null
#  read_at              :timestamp(6) without time zone null
#  data                 :jsonb              null, default("{}")
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#
# Indexes
#
#  index_notifications_on_actor_id (actor_id)
#  index_notifications_on_notifiable (notifiable_type,notifiable_id)
#  index_notifications_on_recipient_id (recipient_id)
#  index_notifications_on_recipient_id_and_read_at (recipient_id,read_at)
#
