# frozen_string_literal: true

module Memberships
  class IntegrityCalculator < ApplicationService
    LOOKBACK_DAYS = 14
    BASE_PENALTY = 5.0

    attr_reader :membership, :reference_date, :timezone

    def initialize(membership:, reference_date: nil, timezone: "UTC")
      super()
      @membership = membership
      @reference_date = reference_date || Date.current
      @timezone = timezone
    end

    def call
      group = membership.group
      end_date = reference_date
      start_date = end_date - (LOOKBACK_DAYS - 1).days

      current_period = current_period_for_group(group, end_date)
      active_steps = group.group_steps.kept.where("position <= ?", current_period).order(:position)

      total_penalty = 0.0
      active_steps.each do |step|
        expected = expected_logs_for_step(step)
        actual = count_logs_for_step(step, start_date, end_date)
        missing = [expected - actual, 0].max
        penalty_per_missing = BASE_PENALTY / step.position
        total_penalty += missing * penalty_per_missing
      end

      score = (100.0 - total_penalty).round(2)
      score = [[score, 0].max, 100].min
      success(score)
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

    def expected_logs_for_step(step)
      # From step.requirements or group.rules; default daily = 14 in 14 days
      freq = step.requirements["frequency"] || step.requirements["frequency_per_week"] || "daily"
      case freq.to_s
      when "weekly" then 2
      when "monthly" then 1
      else LOOKBACK_DAYS
      end
    end

    def count_logs_for_step(step, start_date, end_date)
      start_time = start_date.in_time_zone(timezone).beginning_of_day.utc
      end_time = end_date.in_time_zone(timezone).end_of_day.utc

      membership.progress_logs.kept
        .where(group_step_id: step.id)
        .where(occurred_at: start_time..end_time)
        .count
    end
  end
end
