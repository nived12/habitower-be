# frozen_string_literal: true

class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  USERNAME_FORMAT = /\A[a-zA-Z0-9_]+\z/

  devise :database_authenticatable, :registerable,
    :validatable, :jwt_authenticatable,
    jwt_revocation_strategy: self

  validates :username,
    uniqueness: { case_sensitive: false },
    format: { with: USERNAME_FORMAT, message: "only allows letters, numbers, and underscores" },
    length: { minimum: 3, maximum: 30 },
    allow_blank: true

  has_many :created_challenge_templates, class_name: "ChallengeTemplate", foreign_key: :creator_id, dependent: :nullify
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :refresh_tokens, dependent: :destroy
  has_many :devices, dependent: :destroy

  scope :by_email_or_username, ->(identifier) {
    where("LOWER(email) = LOWER(?) OR LOWER(username) = LOWER(?)", identifier, identifier)
  }

  # Set jti on user when dispatching a token so JTIMatcher can revoke on logout
  def jwt_payload
    self.jti = self.class.generate_jti
    save!
    super.merge("jti" => jti)
  end
end

# == Schema Information
#
# Table name: users
#
#  id                   :integer            not null, primary key
#  email                :string             not null
#  encrypted_password   :string             not null
#  reset_password_token :string             null
#  reset_password_sent_at :timestamp(6) without time zone null
#  remember_created_at  :timestamp(6) without time zone null
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#  jti                  :string             null
#  first_name           :string             null
#  last_name            :string             null
#  avatar_url           :string             null
#  username             :string             null
#
# Indexes
#
#  index_users_on_email (email) UNIQUE
#  index_users_on_jti (jti) UNIQUE
#  index_users_on_reset_password_token (reset_password_token) UNIQUE
#  index_users_on_username (username) UNIQUE
#
