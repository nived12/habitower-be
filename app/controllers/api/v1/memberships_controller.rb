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
        authorize(@group, :show?)

        if params[:identifier].present?
          result = Groups::MemberAdder.call(
            group: @group,
            identifier: params[:identifier],
            current_user: current_user,
            role: params[:role] || "member",
          )
        else
          result = Groups::Joiner.call(
            group: @group,
            user: current_user,
            invite_code: params[:invite_code],
          )
        end

        if result.failure?
          http_status = case result.errors.full_messages.first
          when /not found/ then :not_found
          when /Only group admins/ then :forbidden
          when /Invalid invite/ then :forbidden
          else :unprocessable_content
          end
          status_code = http_status == :not_found ? "404" : (http_status == :forbidden ? "403" : "422")
          render_error(status_code, result.errors.full_messages.first, http_status)
          return
        end

        @membership = result.payload
        render(:show, status: :created)
      end

      # DELETE /api/v1/groups/:group_id/memberships/:id (leave or admin remove)
      def destroy
        authorize(@group, :show?)

        membership = @group.memberships.kept.find(params[:id])
        can_leave = membership.user_id == current_user.id
        can_remove = @group.memberships.kept.exists?(user_id: current_user.id, role: "admin")
        if can_leave && @group.creator_id == current_user.id
          render_error("403", "Creator cannot leave", :forbidden)
          return
        end
        unless can_leave || can_remove
          render_error("403", "Only group admins can remove other members", :forbidden)
          return
        end

        membership.discard!
        head(:no_content)
      end

      # GET /api/v1/groups/:group_id/memberships/:id/active-stack
      def active_stack
        result = Groups::ActiveStackFetcher.call(
          membership: @membership,
          user_timezone: params[:user_timezone].presence || "UTC",
        )
        if result.failure?
          render_error("422", result.errors.full_messages.first, :unprocessable_content)
          return
        end
        @active_stack_items = result.payload
      end

      # GET /api/v1/groups/:group_id/memberships/:id/integrity
      def integrity
        result = Memberships::IntegrityCalculator.call(
          membership: @membership,
          timezone: params[:user_timezone].presence || "UTC",
        )
        if result.failure?
          render_error("422", result.errors.full_messages.first, :unprocessable_content)
          return
        end
        @integrity_score = result.payload
      end

      private

      def set_group
        @group = Group.kept.find(params[:group_id])
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
