# frozen_string_literal: true

module Api
  module V1
    class ProgressLogsController < BaseController
      # POST /api/v1/progress_logs
      def create
        group_step = GroupStep.kept.find(params[:group_step_id])
        membership = current_user.memberships.kept.find_by!(group_id: group_step.group_id)
        result = ProgressLogs::Creator.call(
          membership: membership,
          group_step_id: params[:group_step_id],
          value: params[:value],
          occurred_at: params[:occurred_at].presence || Time.current,
          note: params[:note],
          proof_url: params[:proof_url]
        )

        if result.failure?
          render_service_errors(result.errors)
          return
        end

        @progress_log = result.payload
        render(:show, status: :created)
      end

      private
    end
  end
end
