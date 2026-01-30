# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound do |_e|
        render_not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render_validation_errors(e.record)
      end

      private

      def render_not_found
        render(
          json: {
                    errors: [
                      { status: "404", source: { pointer: "/data" }, detail: "Record not found" }
                    ]
                  }, status: :not_found
        )
      end

      def render_validation_errors(record)
        errors = record.errors.map do |error|
          {
            status: "422",
            source: { pointer: "/data/attributes/#{error.attribute}" },
            detail: error.message
          }
        end
        render(json: { errors: errors }, status: :unprocessable_entity)
      end
    end
  end
end
