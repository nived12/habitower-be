# frozen_string_literal: true

class Category < ApplicationRecord
  has_many :challenge_template_categories, dependent: :destroy
  has_many :challenge_templates, through: :challenge_template_categories

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
end

# == Schema Information
#
# Table name: categories
#
#  id                   :integer            not null, primary key
#  name                 :string             not null
#  slug                 :string             not null
#  created_at           :timestamp(6) without time zone not null
#  updated_at           :timestamp(6) without time zone not null
#  icon                 :string             null
#
# Indexes
#
#  index_categories_on_slug (slug) UNIQUE
#
