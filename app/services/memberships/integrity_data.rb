# frozen_string_literal: true

module Memberships
  # Builds integrity data (score + ghost_tower) for multiple memberships.
  # This is a plain module, not a service: it composes IntegrityScoreCalculator and
  # GhostTowerBuilder so callers get one batch result without a service calling other services.
  module IntegrityData
    module_function

    # @param memberships [Array<Membership>]
    # @param timezone [String]
    # @param reference_date [Date, nil]
    # @return [Hash<Integer, Hash>] membership_id => { score:, ghost_tower: }
    def for_batch(memberships, timezone: "UTC", reference_date: nil)
      ref = reference_date || Date.current
      result = {}

      memberships.each do |membership|
        score_result = IntegrityScoreCalculator.call(
          membership: membership,
          reference_date: ref,
          timezone: timezone,
        )
        next unless score_result.success?

        ghost_result = GhostTowerBuilder.call(
          membership: membership,
          reference_date: ref,
          timezone: timezone,
        )
        next unless ghost_result.success?

        result[membership.id] = {
          score: score_result.payload,
          ghost_tower: ghost_result.payload
        }
      end

      result
    end
  end
end
