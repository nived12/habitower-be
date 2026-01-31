# frozen_string_literal: true

module Api
  module V1
    module ErrorHandler
      extend ActiveSupport::Concern

      included do
        rescue_from ActiveRecord::RecordNotFound do |_e|
          render_not_found
        end

        rescue_from ActiveRecord::RecordInvalid do |e|
          render_validation_errors(e.record)
        end

        rescue_from Pundit::NotAuthorizedError do |_e|
          render_forbidden
        end
      end

      private

      def render_not_found
        render(
          json: {
            errors: [
              { status: "404", source: { pointer: "/data" }, detail: "Record not found" }
            ]
          },
          status: :not_found
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
        render(json: { errors: errors }, status: :unprocessable_content)
      end

      def render_forbidden
        render(
          json: {
            errors: [
              { status: "403", source: { pointer: "/data" }, detail: "Forbidden" }
            ]
          },
          status: :forbidden
        )
      end

      def render_error(status_code, detail, http_status = :unprocessable_content)
        render(
          json: {
            errors: [
              { status: status_code, source: { pointer: "/data" }, detail: detail }
            ]
          },
          status: http_status,
        )
      end

      def render_service_errors(errors)
        api_errors = errors.map do |error|
          {
            status: "422",
            source: { pointer: "/data/attributes/#{error.attribute}" },
            detail: error.message
          }
        end
        render(json: { errors: api_errors }, status: :unprocessable_content)
      end
    end
  end
end
