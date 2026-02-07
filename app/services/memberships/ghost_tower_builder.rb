# frozen_string_literal: true

module Memberships
  # Builds a "ghost tower": a small snapshot of the top steps of the stack and whether
  # the member completed or missed each on the reference date (single day only).
  class GhostTowerBuilder < ApplicationService
    include PeriodForGroup

    GHOST_TOWER_SIZE = 3

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

      current_period = current_period_for_group(group, end_date)
      active_steps = group.group_steps.kept.where("position <= ?", current_period).order(:position).to_a
      steps_to_show = active_steps.last(GHOST_TOWER_SIZE)

      start_time = end_date.in_time_zone(timezone).beginning_of_day.utc
      end_time = end_date.in_time_zone(timezone).end_of_day.utc

      ghost_tower = steps_to_show.map do |step|
        has_log = membership.progress_logs.kept
          .where(group_step_id: step.id)
          .where(occurred_at: start_time..end_time)
          .exists?
        status = has_log ? "completed" : "missed"
        { position: step.position, status: status }
      end

      success(ghost_tower)
    end

    private
  end
end
