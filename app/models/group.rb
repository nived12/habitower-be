# frozen_string_literal: true

class Group < ApplicationRecord
  enum :privacy_type, { public: "public", private: "private" }, validate: true, prefix: true

  belongs_to :challenge
  belongs_to :creator, class_name: "User"
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
end
