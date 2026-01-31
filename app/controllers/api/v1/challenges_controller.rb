# frozen_string_literal: true

module Api
  module V1
    class ChallengesController < BaseController
      before_action :set_challenge, only: [:show, :update, :destroy]

      def index
        authorize(Challenge)

        @challenges = policy_scope(Challenge.kept)
      end

      def show
        authorize(@challenge)
      end

      def create
        @challenge = Challenge.new(challenge_params)
        @challenge.creator = current_user

        authorize(@challenge)

        @challenge.save!

        render(:show, status: :created)
      end

      def update
        authorize(@challenge)

        @challenge.update!(challenge_params)

        render(:show, status: :ok)
      end

      def destroy
        authorize(@challenge)

        @challenge.discard!

        head(:no_content)
      end

      private

      def set_challenge
        @challenge = Challenge.kept.find(params[:id])
      end

      def challenge_params
        params.require(:challenge).permit(:title, :description, :period_type, :privacy_type, rules: {})
      end
    end
  end
end
