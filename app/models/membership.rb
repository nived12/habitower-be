# frozen_string_literal: true

class Membership < ApplicationRecord
  enum :role, { member: "member", admin: "admin" }, validate: true
  enum :status, { active: "active", inactive: "inactive" }, validate: true

  belongs_to :user
  belongs_to :group
  has_many :progress_logs, dependent: :destroy
end
