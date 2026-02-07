# frozen_string_literal: true

json.progress_log_id(@progress_log.id)
json.reacted_by_me(@reacted_by_me)
json.reactions_count(@reactions_count)
json.stats do
  json.high_fives_count(@reactions_by_kind["high_five"] || 0)
  json.nudges_count(@reactions_by_kind["nudge"] || 0)
end
