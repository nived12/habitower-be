# frozen_string_literal: true

json.notifications(@notifications) do |notification|
  json.id(notification.id)
  json.action(notification.action)
  json.read_at(notification.read_at)
  json.created_at(notification.created_at)
  json.data(notification.data)
  if notification.actor.present?
    json.actor do
      json.id(notification.actor.id)
      json.username(notification.actor.username)
      json.avatar_url(notification.actor.avatar_url)
    end
  else
    json.actor(nil)
  end
  if notification.notifiable.present?
    json.notifiable_type(notification.notifiable_type)
    json.notifiable_id(notification.notifiable_id)
  end
end

json.meta(@meta)
