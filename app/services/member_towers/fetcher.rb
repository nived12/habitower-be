# frozen_string_literal: true

module MemberTowers
  class Fetcher < ApplicationService
    DEFAULT_PER_PAGE = 10

    attr_reader :group, :current_user, :page, :per_page, :reference_date, :timezone

    def initialize(group:, current_user:, page: 1, per_page: DEFAULT_PER_PAGE, reference_date: nil, timezone: "UTC")
      super()
      @group = group
      @current_user = current_user
      @page = [page.to_i, 1].max
      @per_page = [[per_page.to_i, 1].max, 100].min
      @reference_date = parse_reference_date(reference_date)
      @timezone = timezone.presence || "UTC"
    end

    def call
      return failure("Invalid date") if reference_date.nil?

      ordered = ordered_memberships
      total = ordered.size
      page_memberships = ordered.slice((page - 1) * per_page, per_page) || []

      return success(
        meta: { page: page, per_page: per_page, total: total },
        member_towers: []
      ) if page_memberships.empty?

      integrity_data = Memberships::IntegrityCalculator.batch(
        page_memberships,
        timezone: timezone,
        reference_date: reference_date
      )

      member_towers = page_memberships.map do |membership|
        data = integrity_data[membership.id] || {}
        {
          membership: membership,
          user: membership.user,
          integrity_score: data[:score],
          ghost_tower: data[:ghost_tower] || [],
          is_current_user: membership.user_id == current_user.id
        }
      end

      meta = { page: page, per_page: per_page, total: total }
      success(meta: meta, member_towers: member_towers)
    end

    private

    def ordered_memberships
      memberships = group.memberships.kept.includes(:user).to_a
      current = memberships.find { |m| m.user_id == current_user.id }
      others = memberships.reject { |m| m.user_id == current_user.id }.sort_by(&:id)
      [current, *others].compact
    end

    def parse_reference_date(value)
      return Date.current if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
