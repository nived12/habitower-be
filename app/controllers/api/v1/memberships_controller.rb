# frozen_string_literal: true

module Api
  module V1
    class MembershipsController < BaseController
      before_action :set_group

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

      private

      def set_group
        @group = Group.kept.find(params[:group_id])
      end

      def authorize_admin!
        return true if @group.memberships.kept.exists?(user_id: current_user.id, role: "admin")

        render_error("403", "Only group admins can remove members", :forbidden)
        false
      end
    end
  end
end
