# frozen_string_literal: true

module Api
  module V1
    class GroupsController < BaseController
      before_action :set_group, only: [:show, :update, :destroy, :join, :leave]

      def index
        authorize(Group)
        @groups = policy_scope(Group.kept).includes(:challenge, :creator)
      end

      def show
        authorize(@group)
      end

      def create
        challenge = Challenge.kept.find(params.dig(:group, :challenge_id))

        @group = Groups::Creator.new(
          challenge: challenge,
          creator: current_user,
          privacy_type: group_params[:privacy_type] || "public",
          start_date: group_params[:start_date],
        ).call

        authorize(@group)
        render(:show, status: :created)
      end

      def update
        authorize(@group)

        @group.update!(group_params.except(:challenge_id))
        render(:show, status: :ok)
      end

      def destroy
        authorize(@group)

        @group.discard!
        head(:no_content)
      end

      def join
        authorize(@group)

        @membership = Groups::Joiner.new(
          group: @group,
          user: current_user,
          invite_code: params[:invite_code],
        ).call

        render(:join, status: :created)
      rescue Groups::Joiner::AlreadyMemberError => e
        render_error("422", e.message)
      rescue Groups::Joiner::InvalidInviteCodeError => e
        render_error("403", e.message, :forbidden)
      end

      def leave
        authorize(@group)

        membership = @group.memberships.kept.find_by!(user_id: current_user.id)
        membership.discard!
        head(:no_content)
      end

      private

      def set_group
        @group = Group.kept.find(params[:id])
      end

      def group_params
        params.require(:group).permit(:challenge_id, :privacy_type, :start_date)
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
