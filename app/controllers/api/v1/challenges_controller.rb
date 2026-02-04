# frozen_string_literal: true

module Api
  module V1
    class ChallengesController < BaseController
      before_action :set_challenge, only: [:show, :update, :destroy]

      # GET /api/v1/challenges
      def index
        authorize(ChallengeTemplate)

        @challenges = policy_scope(ChallengeTemplate.kept)
        @challenges = filter_by_category(@challenges) if params[:category_id] || params[:category_slug]
      end

      # GET /api/v1/challenges/:id
      def show
        authorize(@challenge)
      end

      # POST /api/v1/challenges
      def create
        @challenge = ChallengeTemplate.new(challenge_params)
        @challenge.creator = current_user

        authorize(@challenge)

        @challenge.save!

        render(:show, status: :created)
      end

      # PATCH /api/v1/challenges/:id
      def update
        authorize(@challenge)

        @challenge.update!(challenge_params)

        render(:show, status: :ok)
      end

      # DELETE /api/v1/challenges/:id
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
        params.require(:challenge).permit(
          :title, :description, :period_type, :privacy_type, { category_ids: [] },
          rules: {}
        )
      end

      def filter_by_category(scope)
        scope = scope.joins(:categories).distinct
        if params[:category_id].present?
          scope.where(categories: { id: params[:category_id] })
        elsif params[:category_slug].present?
          scope.where(categories: { slug: params[:category_slug] })
        else
          scope
        end
      end
    end
  end
end
