# frozen_string_literal: true

module Api
  module V1
    class MembershipsController < BaseController
      before_action :set_group

      def index
        @memberships = @group.memberships.kept.includes(:user)
      end

      def create
        @membership = Groups::MemberAdder.new(
          group: @group,
          identifier: params[:identifier],
          current_user: current_user,
          role: params[:role] || "member",
        ).call

        render(:show, status: :created)
      rescue Groups::MemberAdder::UserNotFoundError => e
        render_error("404", e.message, :not_found)
      rescue Groups::MemberAdder::AlreadyMemberError => e
        render_error("422", e.message)
      rescue Groups::MemberAdder::NotAuthorizedError => e
        render_error("403", e.message, :forbidden)
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

      def render_error(status_code, detail, http_status = :unprocessable_entity)
        render(
          json: {
            errors: [
              { status: status_code, source: { pointer: "/data" }, detail: detail }
            ]
          },
          status: http_status,
        )
      end
    end
  end
end
