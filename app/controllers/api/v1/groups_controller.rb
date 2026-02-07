# frozen_string_literal: true

module Api
  module V1
    class GroupsController < BaseController
      before_action :set_group, only: [:show, :update, :destroy]

      # GET /api/v1/groups
      def index
        authorize(Group)

        @groups = policy_scope(Group.kept).includes(:challenge_template, :creator)
      end

      # GET /api/v1/groups/:id
      def show
        authorize(@group)
        @include_members = params[:include_members].present?
        if @include_members
          @members = @group.memberships.kept.includes(:user)
          timezone = params[:user_timezone].presence || "UTC"
          @integrity_data = Memberships::IntegrityData.for_batch(@members, timezone: timezone)
        end
      end

      # POST /api/v1/groups
      def create
        challenge_template = ChallengeTemplate.kept.find(params.dig(:group, :challenge_template_id))

        result = Groups::Creator.call(
          challenge_template: challenge_template,
          creator: current_user,
          privacy_type: group_params[:privacy_type] || "public",
          start_date: group_params[:start_date],
          title: group_params[:title]
        )

        if result.failure?
          render_service_errors(result.errors)
          return
        end

        @group = result.payload
        authorize(@group)
        render(:show, status: :created)
      end

      # PATCH /api/v1/groups/:id
      def update
        authorize(@group)

        @group.update!(group_params.except(:challenge_template_id))
        render(:show, status: :ok)
      end

      # DELETE /api/v1/groups/:id
      def destroy
        authorize(@group)

        @group.discard!
        head(:no_content)
      end

      private

      def set_group
        @group = Group.kept.find(params[:id])
      end

      def group_params
        params.require(:group).permit(:challenge_template_id, :privacy_type, :start_date, :title)
      end
    end
  end
end
