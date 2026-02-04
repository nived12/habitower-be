# frozen_string_literal: true

json.feed(@feed) do |item|
  json.id(item[:id])
  json.value(item[:value])
  json.note(item[:note])
  json.proof_url(item[:proof_url])
  json.occurred_at(item[:occurred_at])
  json.user(item[:user])
  json.group_step(item[:group_step])
  json.group(item[:group])
  json.stats(item[:stats])
  json.viewer_context(item[:viewer_context])
end

json.meta(@meta)
