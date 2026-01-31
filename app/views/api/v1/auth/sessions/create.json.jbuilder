# frozen_string_literal: true

json.partial!("api/v1/auth/auth_user", user: @user)
if defined?(@refresh_token) && @refresh_token
  json.refresh_token @refresh_token.token
  json.refresh_token_expires_at @refresh_token.expires_at
end
