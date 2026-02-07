# frozen_string_literal: true

json.user do
  json.id(@user.id)
  json.email(@user.email)
  json.username(@user.username)
  json.first_name(@user.first_name)
  json.last_name(@user.last_name)
  json.avatar_url(@user.avatar_url)
  json.bio(@user.bio)
  json.timezone(@user.timezone)
  json.created_at(@user.created_at)
end

json.stats(@stats)
