# frozen_string_literal: true

module Api
  module V1
    class FeedController < BaseController
      def index
        result = Feed::Fetcher.call(
          user: current_user,
          scope: params[:scope].presence || "all",
          page: params[:page],
          per_page: params[:per_page]
        )

        if result.failure?
          render_error("422", result.errors.full_messages.first, :unprocessable_content)
          return
        end

        @feed = result.payload[:feed]
        @meta = result.payload[:meta]
      end
    end
  end
end
