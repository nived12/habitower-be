# frozen_string_literal: true

class ChallengeStep < ApplicationRecord
  belongs_to :challenge
  belongs_to :creator, class_name: "User"
  has_many :progress_logs, dependent: :destroy
end
