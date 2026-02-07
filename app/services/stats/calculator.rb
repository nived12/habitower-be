# frozen_string_literal: true

module Stats
  class Calculator < ApplicationService
    attr_reader :user

    def initialize(user:)
      super()
      @user = user
    end

    def call
      total_blocks = user.memberships.kept
        .joins(:progress_logs)
        .where(progress_logs: { discarded_at: nil })
        .count

      current_streak = compute_current_streak

      success(
        total_blocks: total_blocks,
        current_streak: current_streak,
        groups_count: user.memberships.kept.count
      )
    end

    private

    def compute_current_streak
      timezone = user.timezone.presence || "UTC"
      today = Time.current.in_time_zone(timezone).to_date
      streak = 0
      date = today

      loop do
        day_start = date.in_time_zone(timezone).beginning_of_day.utc
        day_end = date.in_time_zone(timezone).end_of_day.utc
        has_log = user.memberships.kept
          .joins(:progress_logs)
          .where(progress_logs: { discarded_at: nil })
          .where(progress_logs: { occurred_at: day_start..day_end })
          .exists?

        break unless has_log

        streak += 1
        date -= 1.day
      end

      streak
    end
  end
end
