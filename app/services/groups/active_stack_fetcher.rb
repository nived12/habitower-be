# frozen_string_literal: true

module Groups
  class ActiveStackFetcher < ApplicationService
    attr_reader :membership, :user_timezone

    def initialize(membership:, user_timezone: "UTC")
      super()
      @membership = membership
      @user_timezone = user_timezone
    end

    def call
      group = membership.group
      today_local = Time.current.in_time_zone(user_timezone).to_date
      today_start = today_local.in_time_zone(user_timezone).beginning_of_day.utc
      today_end = today_local.in_time_zone(user_timezone).end_of_day.utc

      current_period = current_period_for_group(group, today_local)
      steps = group.group_steps.kept
        .where("position <= ?", current_period)
        .order(:position)

      today_logs_by_step = membership.progress_logs.kept
        .where(group_step_id: steps.select(:id))
        .where(occurred_at: today_start..today_end)
        .index_by(&:group_step_id)

      items = steps.map do |step|
        log = today_logs_by_step[step.id]
        {
          group_step: step,
          completed_today: log.present?,
          today_log_id: log&.id,
          occurred_at: log&.occurred_at
        }
      end

      success(items)
    end

    private

    def current_period_for_group(group, on_date)
      return 0 if group.start_date > on_date

      if group.challenge_template.weekly?
        ((on_date - group.start_date).to_i / 7) + 1
      else
        (on_date.year * 12 + on_date.month) - (group.start_date.year * 12 + group.start_date.month) + 1
      end
    end
  end
end
