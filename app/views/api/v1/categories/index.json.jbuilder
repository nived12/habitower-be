# frozen_string_literal: true

json.categories(@categories) do |category|
  json.id(category.id)
  json.name(category.name)
  json.slug(category.slug)
  json.icon(category.icon)
end
