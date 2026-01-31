# frozen_string_literal: true

json.extract!(group, :id, :challenge_id, :creator_id, :start_date, :privacy_type, :created_at, :updated_at)

# Only show invite_code to members or creator
if group.creator_id == current_user&.id || group.memberships.exists?(user_id: current_user&.id)
  json.invite_code(group.invite_code)
end

json.current_period(group.current_period)
json.members_count(group.memberships.kept.count)
