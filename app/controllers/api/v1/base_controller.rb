# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization

      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound do |_e|
        render_not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render_validation_errors(e.record)
      end

      rescue_from Pundit::NotAuthorizedError do |_e|
        render_forbidden
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

      def render_forbidden
        render(
          json: {
            errors: [
              { status: "403", source: { pointer: "/data" }, detail: "Forbidden" }
            ]
          }, status: :forbidden
        )
      end
    end
  end
end
