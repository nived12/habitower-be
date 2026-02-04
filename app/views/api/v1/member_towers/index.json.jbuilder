# frozen_string_literal: true

json.meta do
  json.page(@meta[:page])
  json.per_page(@meta[:per_page])
  json.total(@meta[:total])
end

json.member_towers(@member_towers) do |item|
  json.membership_id(item[:membership].id)
  json.is_current_user(item[:is_current_user])
  json.user do
    json.id(item[:user].id)
    json.username(item[:user].username)
    json.avatar_url(item[:user].avatar_url)
  end
  json.integrity_score(item[:integrity_score])
  json.ghost_tower(item[:ghost_tower])
end
