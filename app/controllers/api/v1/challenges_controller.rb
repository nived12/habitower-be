# frozen_string_literal: true

module Api
  module V1
    class ChallengesController < BaseController
      before_action :set_challenge, only: [:show, :update, :destroy]

      def index
        authorize(ChallengeTemplate)

        @challenges = policy_scope(ChallengeTemplate.kept)
        @challenges = filter_by_category(@challenges) if params[:category_id] || params[:category_slug]
      end

      def show
        authorize(@challenge)
      end

      def create
        @challenge = ChallengeTemplate.new(challenge_params)
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
        @challenge = ChallengeTemplate.kept.find(params[:id])
      end

      def challenge_params
        params.require(:challenge).permit(:title, :description, :period_type, :privacy_type, rules: {})
      end

      def filter_by_category(scope)
        if params[:category_id].present?
          scope.joins(:categories).where(categories: { id: params[:category_id] })
        elsif params[:category_slug].present?
          scope.joins(:categories).where(categories: { slug: params[:category_slug] })
        else
          scope
        end.distinct
      end
    end
  end
end
