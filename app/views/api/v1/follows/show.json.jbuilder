# frozen_string_literal: true

json.follow do
  json.id(@follow.id)
  json.followed_id(@follow.followed_id)
  json.follower_id(@follow.follower_id)
  json.followed do
    json.id(@follow.followed.id)
    json.username(@follow.followed.username)
    json.first_name(@follow.followed.first_name)
    json.last_name(@follow.followed.last_name)
    json.avatar_url(@follow.followed.avatar_url)
  end
end
