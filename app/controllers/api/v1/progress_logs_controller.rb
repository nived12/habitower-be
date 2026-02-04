# frozen_string_literal: true

module Api
  module V1
    class ProgressLogsController < BaseController
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

      def react
        progress_log = ProgressLog.kept.find(params[:id])
        authorize_progress_log!(progress_log)

        kind = params[:kind].presence || "high_five"
        unless Reaction.kinds.key?(kind)
          render_error("422", "Invalid kind. Use high_five or nudge", :unprocessable_content)
          return
        end

        reaction = progress_log.reactions.find_by(user_id: current_user.id, kind: kind)
        if reaction
          reaction.destroy
          reacted = false
        else
          progress_log.reactions.create!(user: current_user, kind: kind)
          reacted = true
        end

        progress_log.reload
        progress_log.reactions.reload
        @progress_log = progress_log
        @reacted_by_me = progress_log.reactions.where(user_id: current_user.id).pluck(:kind)
        @reactions_count = progress_log.reactions.count
        @reactions_by_kind = progress_log.reactions.group(:kind).count
        render(:react, status: :ok)
      end

      private

      def authorize_progress_log!(progress_log)
        group_ids = current_user.memberships.kept.pluck(:group_id)
        return if group_ids.include?(progress_log.membership.group_id)

        raise(Pundit::NotAuthorizedError)
      end
    end
  end
end
