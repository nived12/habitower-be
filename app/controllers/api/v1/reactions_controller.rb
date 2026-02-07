# frozen_string_literal: true

module Api
  module V1
    class ReactionsController < BaseController
      before_action :set_progress_log
      before_action :authorize_progress_log!
      before_action :set_reaction, only: [:destroy]

      # POST /api/v1/progress_logs/:progress_log_id/reactions
      def create
        kind = params[:kind].presence || "high_five"
        unless Reaction.kinds.key?(kind)
          render_error("422", "Invalid kind. Use high_five or nudge", :unprocessable_content)
          return
        end

        reaction = @progress_log.reactions.find_by(user_id: current_user.id, kind: kind)
        if reaction
          reaction.destroy
          reacted = false
        else
          @progress_log.reactions.create!(user: current_user, kind: kind)
          reacted = true
        end

        @progress_log.reload
        @progress_log.reactions.reload
        @reacted_by_me = @progress_log.reactions.where(user_id: current_user.id).pluck(:kind)
        @reactions_count = @progress_log.reactions.count
        @reactions_by_kind = @progress_log.reactions.group(:kind).count

        render(:create, status: reacted ? :created : :ok)
      end

      # DELETE /api/v1/progress_logs/:progress_log_id/reactions/:id
      def destroy
        @reaction.destroy
        @progress_log.reload
        @progress_log.reactions.reload
        @reacted_by_me = @progress_log.reactions.where(user_id: current_user.id).pluck(:kind)
        @reactions_count = @progress_log.reactions.count
        @reactions_by_kind = @progress_log.reactions.group(:kind).count
        render(:destroy, status: :ok)
      end

      private

      def set_progress_log
        @progress_log = ProgressLog.kept.find(params[:progress_log_id])
      end

      def set_reaction
        @reaction = @progress_log.reactions.find(params[:id])
        return if @reaction.user_id == current_user.id

        raise(Pundit::NotAuthorizedError)
      end

      def authorize_progress_log!
        group_ids = current_user.memberships.kept.pluck(:group_id)
        return if group_ids.include?(@progress_log.membership.group_id)

        raise(Pundit::NotAuthorizedError)
      end
    end
  end
end
