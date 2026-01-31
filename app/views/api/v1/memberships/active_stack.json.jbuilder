# frozen_string_literal: true

json.array!(@active_stack_items) do |item|
  json.group_step do
    json.extract!(item[:group_step], :id, :title, :position, :requirements, :group_id, :original_step_id)
  end
  json.completed_today(item[:completed_today])
  json.today_log_id(item[:today_log_id])
  json.occurred_at(item[:occurred_at])
end
