# frozen_string_literal: true

module Api
  module V1
    class GroupsController < BaseController
      before_action :set_group, only: [:show, :update, :destroy, :join, :leave]

      def index
        authorize(Group)

        @groups = policy_scope(Group.kept).includes(:challenge_template, :creator)
      end

      def show
        authorize(@group)
        @include_members = params[:include_members].present?
        if @include_members
          @members = @group.memberships.kept.includes(:user)
          timezone = params[:user_timezone].presence || "UTC"
          @integrity_data = Memberships::IntegrityCalculator.batch(@members, timezone: timezone)
        end
      end

      def create
        challenge_template = ChallengeTemplate.kept.find(params.dig(:group, :challenge_template_id))

        result = Groups::Creator.call(
          challenge_template: challenge_template,
          creator: current_user,
          privacy_type: group_params[:privacy_type] || "public",
          start_date: group_params[:start_date],
        )

        if result.failure?
          render_service_errors(result.errors)
          return
        end

        @group = result.payload
        authorize(@group)
        render(:show, status: :created)
      end

      def update
        authorize(@group)

        @group.update!(group_params.except(:challenge_template_id))
        render(:show, status: :ok)
      end

      def destroy
        authorize(@group)

        @group.discard!
        head(:no_content)
      end

      def join
        authorize(@group)

        result = Groups::Joiner.call(
          group: @group,
          user: current_user,
          invite_code: params[:invite_code],
        )

        if result.failure?
          status_code = result.errors.full_messages.first&.include?("Invalid invite") ? "403" : "422"
          http_status = status_code == "403" ? :forbidden : :unprocessable_content
          render_error(status_code, result.errors.full_messages.first, http_status)
          return
        end

        @membership = result.payload
        render(:join, status: :created)
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
        params.require(:group).permit(:challenge_template_id, :privacy_type, :start_date)
      end
    end
  end
end
