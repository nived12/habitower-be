# frozen_string_literal: true

class Group < ApplicationRecord
  include Discard::Model

  validates :start_date, presence: true

  enum :privacy_type, { public: "public", private: "private" }, default: :public, validate: true, prefix: true

  belongs_to :challenge
  belongs_to :creator, class_name: "User"
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  after_discard { memberships.discard_all }
end

# == Schema Information
#
# Table name: groups
#
#  id                   :integer            not null, primary key
#  challenge_id         :integer            not null
#  creator_id           :integer            not null
#  start_date           :date               not null
#  privacy_type         :string             not null, default("public")
#  invite_code          :string             null
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#  discarded_at         :timestamp(6) without time zone null
#
# Indexes
#
#  index_groups_on_challenge_id (challenge_id)
#  index_groups_on_creator_id (creator_id)
#  index_groups_on_discarded_at (discarded_at)
#  index_groups_on_invite_code (invite_code)
#
