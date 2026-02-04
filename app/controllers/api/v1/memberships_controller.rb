# frozen_string_literal: true

module Api
  module V1
    class MembershipsController < BaseController
      before_action :set_group, except: [:active_stack, :integrity]
      before_action :set_membership_for_member_routes, only: [:active_stack, :integrity]

      def index
        @memberships = @group.memberships.kept.includes(:user)
      end

      def create
        result = Groups::MemberAdder.call(
          group: @group,
          identifier: params[:identifier],
          current_user: current_user,
          role: params[:role] || "member",
        )

        if result.failure?
          http_status = case result.errors.full_messages.first
          when /not found/ then :not_found
          when /Only group admins/ then :forbidden
          else :unprocessable_content
          end
          status_code = http_status == :not_found ? "404" : (http_status == :forbidden ? "403" : "422")
          render_error(status_code, result.errors.full_messages.first, http_status)
          return
        end

        @membership = result.payload
        render(:show, status: :created)
      end

      def destroy
        membership = @group.memberships.kept.find(params[:id])
        return unless authorize_admin!

        membership.discard!
        head(:no_content)
      end

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
        @membership = Membership.kept.find(params[:id])
        membership_user = @membership.user_id
        group_admin = @membership.group.memberships.kept.exists?(user_id: current_user.id, role: "admin")
        return if current_user.id == membership_user || group_admin

        raise(Pundit::NotAuthorizedError)
      end

      def authorize_admin!
        return true if @group.memberships.kept.exists?(user_id: current_user.id, role: "admin")

        render_error("403", "Only group admins can remove members", :forbidden)
        false
      end
    end
  end
end
