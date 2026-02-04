# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < BaseController
      # GET /api/v1/categories
      def index
        @categories = Category.order(:name)
      end
    end
  end
end
