# frozen_string_literal: true

class RefreshToken < ApplicationRecord
  belongs_to :user

  scope :valid, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
end

# == Schema Information
#
# Table name: refresh_tokens
#
#  id                   :integer            not null, primary key
#  user_id              :integer            not null
#  token                :string             not null
#  expires_at           :timestamp(6) without time zone not null
#  revoked_at           :timestamp(6) without time zone null
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#
# Indexes
#
#  index_refresh_tokens_on_token (token) UNIQUE
#  index_refresh_tokens_on_user_id (user_id)
#
