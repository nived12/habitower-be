# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < BaseController
      def index
        @categories = Category.order(:name)
      end
    end
  end
end
