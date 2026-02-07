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
          status: http_status
        )
      end

      # Renders error with status code derived from http_status. Use for service failures.
      def render_error_for_status(detail, http_status = :unprocessable_content)
        render_error(default_status_code_for(http_status), detail, http_status)
      end

      def default_status_code_for(http_status)
        case http_status
        when :not_found then "404"
        when :forbidden then "403"
        when :unauthorized then "401"
        when :internal_server_error then "500"
        else "422"
        end
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
