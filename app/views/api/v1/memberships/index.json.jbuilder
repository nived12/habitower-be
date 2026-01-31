# frozen_string_literal: true

json.array!(@memberships) do |membership|
  json.partial!("api/v1/memberships/membership", membership: membership)
  json.user do
    json.extract!(membership.user, :id, :email, :username, :first_name, :last_name, :avatar_url)
  end
end
