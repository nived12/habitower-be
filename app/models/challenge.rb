# frozen_string_literal: true

class Challenge < ApplicationRecord
  enum :period_type, { weekly: "weekly", monthly: "monthly" }, validate: true

  belongs_to :creator, class_name: "User"
  has_many :challenge_steps, dependent: :destroy
  has_many :groups, dependent: :destroy
end
