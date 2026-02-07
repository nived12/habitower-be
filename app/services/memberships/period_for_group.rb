# frozen_string_literal: true

module Memberships
  # Shared logic for computing the current period index of a group (weekly or monthly).
  module PeriodForGroup
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
