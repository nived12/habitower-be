# frozen_string_literal: true

class ChallengeTemplateCategory < ApplicationRecord
  belongs_to :challenge_template
  belongs_to :category

  validates :challenge_template_id, uniqueness: { scope: :category_id }
end

# == Schema Information
#
# Table name: challenge_template_categories
#
#  id                   :integer            not null, primary key
#  challenge_template_id :integer            not null
#  category_id          :integer            not null
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#
# Indexes
#
#  idx_template_categories_unique (challenge_template_id,category_id) UNIQUE
#  index_challenge_template_categories_on_category_id (category_id)
#  index_challenge_template_categories_on_challenge_template_id (challenge_template_id)
#
