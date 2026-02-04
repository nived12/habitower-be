# frozen_string_literal: true

module Feed
  class Fetcher < ApplicationService
    DEFAULT_PER_PAGE = 20
    SCOPES = %w[all mine friends].freeze

    attr_reader :user, :scope, :page, :per_page

    def initialize(user:, scope: "all", page: 1, per_page: DEFAULT_PER_PAGE)
      super()
      @user = user
      @scope = scope.to_s.downcase
      @page = [page.to_i, 1].max
      @per_page = [[per_page.to_i, 1].max, 100].min
    end

    def call
      return failure("Invalid scope") unless SCOPES.include?(scope)

      relation = base_relation
      relation = apply_scope(relation)
      total = relation.count
      logs = relation
        .includes(membership: :user, group_step: :group)
        .includes(:reactions)
        .order(occurred_at: :desc)
        .offset((page - 1) * per_page)
        .limit(per_page)
        .to_a

      items = logs.map { |log| build_feed_item(log) }
      meta = { page: page, per_page: per_page, total: total }

      success(feed: items, meta: meta)
    end

    private

    def base_relation
      group_ids = user.memberships.kept.pluck(:group_id)
      ProgressLog.kept
        .joins(membership: :group)
        .where(memberships: { group_id: group_ids })
        .where(groups: { discarded_at: nil })
    end

    def apply_scope(relation)
      case scope
      when "mine"
        relation.where(memberships: { user_id: user.id })
      when "friends"
        followed_ids = user.followed_users.pluck(:id)
        relation.where(memberships: { user_id: followed_ids })
      else
        relation
      end
    end

    def build_feed_item(log)
      reactions_by_kind = log.reactions.group_by(&:kind)
      reacted_by_me = log.reactions.select { |r| r.user_id == user.id }.map(&:kind).uniq

      {
        id: log.id,
        value: log.value,
        note: log.note,
        proof_url: log.proof_url,
        occurred_at: log.occurred_at,
        user: {
          id: log.membership.user.id,
          username: log.membership.user.username,
          avatar_url: log.membership.user.avatar_url
        },
        group_step: {
          id: log.group_step.id,
          title: log.group_step.title,
          position: log.group_step.position
        },
        group: {
          id: log.group_step.group.id,
          name: log.group_step.group.challenge_template.title
        },
        stats: {
          reactions_count: log.reactions.size,
          high_fives_count: reactions_by_kind["high_five"]&.size || 0,
          nudges_count: reactions_by_kind["nudge"]&.size || 0
        },
        viewer_context: {
          reacted_by_me: reacted_by_me
        }
      }
    end
  end
end
