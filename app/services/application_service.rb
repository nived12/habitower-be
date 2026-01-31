# frozen_string_literal: true

##
# ApplicationService
# Base for service objects. Use .call(...) to run; implement #call and return success(payload) or failure(message/errors).
#
class ApplicationService
  include Errorable

  attr_accessor :errors

  def self.call(*args, **kwargs, &block)
    new(*args, **kwargs, &block).call
  end

  def initialize(*)
    @errors = ActiveModel::Errors.new(self)
  end

  def success(payload = nil)
    Response.new(success: true, payload: payload, errors: nil)
  end

  def failure(error_message = nil)
    if error_message.present?
      case error_message
      when String
        errors.add(:base, error_message)
      when ActiveModel::Errors
        error_message.each { |e| errors.add(e.attribute, e.message) }
      end
    end

    Rails.logger.error("#{self.class.name}: #{errors.full_messages.join(", ")}") if errors.any?

    Response.new(success: false, payload: nil, errors: errors)
  end

  class Response
    attr_reader :success, :payload, :errors

    def initialize(success:, payload:, errors:)
      @success = success
      @payload = payload
      @errors = errors
    end

    def success?
      @success
    end

    def failure?
      !@success
    end
  end
end
