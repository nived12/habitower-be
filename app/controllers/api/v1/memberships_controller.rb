# frozen_string_literal: true

module Api
  module V1
    class MembershipsController < BaseController
      before_action :set_group
      before_action :set_membership_for_member_routes, only: [:active_stack, :integrity]

      # GET /api/v1/groups/:group_id/memberships
      def index
        @memberships = @group.memberships.kept.includes(:user)
      end

      # POST /api/v1/groups/:group_id/memberships (join with invite_code, or admin add with identifier)
      def create
        authorize(@group, :join?)

        if membership_params[:identifier].present?
          result = Groups::MemberAdder.call(
            group: @group,
            identifier: membership_params[:identifier],
            current_user: current_user,
            role: membership_params[:role] || "member"
          )
        else
          result = Groups::Joiner.call(
            group: @group,
            user: current_user,
            invite_code: membership_params[:invite_code]
          )
        end

        if result.failure?
          render_error_for_status(result.errors.full_messages.first, result.http_status || :unprocessable_content)
          return
        end

        @membership = result.payload
        render(:show, status: :created)
      end

      # DELETE /api/v1/groups/:group_id/memberships/:id (leave or admin remove)
      def destroy
        membership = @group.memberships.kept.find(params[:id])
        authorize(membership)

        membership.discard!
        head(:no_content)
      end

      # GET /api/v1/groups/:group_id/memberships/:id/active-stack
      def active_stack
        result = Groups::ActiveStackFetcher.call(
          membership: @membership,
          user_timezone: params[:user_timezone].presence || "UTC"
        )
        return if render_service_failure(result)

        @active_stack_items = result.payload
      end

      # GET /api/v1/groups/:group_id/memberships/:id/integrity
      def integrity
        result = Memberships::IntegrityScoreCalculator.call(
          membership: @membership,
          timezone: params[:user_timezone].presence || "UTC"
        )
        return if render_service_failure(result)

        @integrity_score = result.payload
      end

      private

      def set_group
        @group = Group.kept.find(params[:group_id])
      end

      def membership_params
        params.permit(:identifier, :invite_code, :role)
      end

      def render_service_failure(result)
        return false unless result.failure?

        render_error_for_status(result.errors.full_messages.first, :unprocessable_content)
        true
      end

      def set_membership_for_member_routes
        @membership = @group.memberships.kept.find(params[:id])
        membership_user = @membership.user_id
        group_admin = @group.memberships.kept.exists?(user_id: current_user.id, role: "admin")
        return if current_user.id == membership_user || group_admin

        raise(Pundit::NotAuthorizedError)
      end
    end
  end
end
