# frozen_string_literal: true

class Device < ApplicationRecord
  validates :token, presence: true

  enum :platform, { ios: "ios", android: "android" }, validate: true

  belongs_to :user
end

# == Schema Information
#
# Table name: devices
#
#  id                   :integer            not null, primary key
#  user_id              :integer            not null
#  platform             :string             not null
#  token                :string             not null
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#
# Indexes
#
#  index_devices_on_user_id (user_id)
#  index_devices_on_user_id_and_platform (user_id,platform) UNIQUE
#
