# frozen_string_literal: true

class ProgressLog < ApplicationRecord
  belongs_to :membership
  belongs_to :challenge_step
end
