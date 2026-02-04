# frozen_string_literal: true

json.partial!("api/v1/groups/group", group: @group)

if defined?(@include_members) && @include_members && @members.present?
  json.members(@members) do |membership|
    json.id(membership.id)
    json.role(membership.role)
    json.user do
      json.id(membership.user.id)
      json.username(membership.user.username)
      json.avatar_url(membership.user.avatar_url)
    end
    data = @integrity_data&.dig(membership.id)
    if data
      json.integrity_score(data[:score])
      json.ghost_tower(data[:ghost_tower])
    end
  end
end
