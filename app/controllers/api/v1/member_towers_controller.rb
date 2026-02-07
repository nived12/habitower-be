# frozen_string_literal: true

module Api
  module V1
    class MemberTowersController < BaseController
      before_action :set_group

      # GET /api/v1/groups/:group_id/member-towers
      def index
        authorize(@group, :show?)

        result = MemberTowers::Fetcher.call(
          group: @group,
          current_user: current_user,
          page: params[:page],
          per_page: params[:per_page],
          reference_date: params[:date],
          timezone: params[:user_timezone]
        )

        if result.failure?
          render_error("422", result.errors.full_messages.first, :unprocessable_content)
          return
        end

        @meta = result.payload[:meta]
        @member_towers = result.payload[:member_towers]
      end

      private

      def set_group
        @group = Group.kept.find(params[:group_id])
      end
    end
  end
end
