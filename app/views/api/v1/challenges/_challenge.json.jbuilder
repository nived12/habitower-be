# frozen_string_literal: true

json.extract!(
  challenge, :id, :title, :description, :period_type, :privacy_type, :rules, :creator_id, :created_at,
  :updated_at
)

json.categories(challenge.categories) do |category|
  json.id(category.id)
  json.name(category.name)
  json.slug(category.slug)
  json.icon(category.icon)
end
