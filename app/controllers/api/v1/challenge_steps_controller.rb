# frozen_string_literal: true

module Api
  module V1
    class ChallengeStepsController < BaseController
      before_action :set_challenge
      before_action :set_challenge_step, only: [:show, :update, :destroy]

      def index
        @challenge_steps = @challenge.challenge_steps.kept.order(:position)

        authorize(@challenge_steps.first || @challenge.challenge_steps.build)
      end

      def show
        authorize(@challenge_step)
      end

      def create
        @challenge_step = @challenge.challenge_steps.build(challenge_step_params)
        @challenge_step.creator = current_user

        authorize(@challenge_step)

        @challenge_step.save!
        render(:show, status: :created)
      end

      def update
        authorize(@challenge_step)

        @challenge_step.update!(challenge_step_params)

        render(:show, status: :ok)
      end

      def destroy
        authorize(@challenge_step)

        @challenge_step.discard!

        head(:no_content)
      end

      private

      def set_challenge
        @challenge = Challenge.kept.find(params[:challenge_id])
      end

      def set_challenge_step
        @challenge_step = @challenge.challenge_steps.kept.find(params[:id])
      end

      def challenge_step_params
        params.require(:challenge_step).permit(:title, :position, requirements: {})
      end
    end
  end
end
