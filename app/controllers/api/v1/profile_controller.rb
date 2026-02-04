# frozen_string_literal: true

module Api
  module V1
    class ProfileController < BaseController
      def show
        @user = current_user
        result = Stats::Calculator.call(user: current_user)
        @stats = result.success? ? result.payload : {}
      end

      def update
        @user = current_user
        if @user.update(profile_params)
          result = Stats::Calculator.call(user: current_user)
          @stats = result.success? ? result.payload : {}
          render(:show, status: :ok)
        else
          render_validation_errors(@user)
        end
      end

      private

      def profile_params
        params.permit(:first_name, :last_name, :avatar_url, :bio, :timezone)
      end
    end
  end
end
