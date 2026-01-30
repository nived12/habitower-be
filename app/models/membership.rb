# frozen_string_literal: true

class Membership < ApplicationRecord
  include Discard::Model

  validates :user_id, uniqueness: { scope: :group_id }

  enum :role, { member: "member", admin: "admin" }, default: :member, validate: true
  enum :status, { active: "active", inactive: "inactive" }, default: :active, validate: true

  belongs_to :user
  belongs_to :group
  has_many :progress_logs, dependent: :destroy

  after_discard { progress_logs.discard_all }
end

# == Schema Information
#
# Table name: memberships
#
#  id                   :integer            not null, primary key
#  user_id              :integer            not null
#  group_id             :integer            not null
#  role                 :string             not null, default("member")
#  status               :string             not null, default("active")
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#  discarded_at         :timestamp(6) without time zone null
#
# Indexes
#
#  index_memberships_on_discarded_at (discarded_at)
#  index_memberships_on_group_id (group_id)
#  index_memberships_on_user_id (user_id)
#  index_memberships_on_user_id_and_group_id (user_id,group_id) UNIQUE
#
