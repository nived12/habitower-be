# frozen_string_literal: true

module Notifications
  class Creator < ApplicationService
    attr_reader :recipient, :actor, :action, :notifiable, :data

    def initialize(recipient:, action:, actor: nil, notifiable: nil, data: {})
      super()
      @recipient = recipient
      @actor = actor
      @action = action
      @notifiable = notifiable
      @data = data.presence || {}
    end

    def call
      return failure("Recipient is required") if recipient.blank?
      return failure("Action is required") if action.blank?
      return failure("Cannot notify self") if actor.present? && actor.id == recipient.id

      notification = Notification.create!(
        recipient: recipient,
        actor: actor,
        action: action,
        notifiable: notifiable,
        data: data
      )

      success(notification)
    end
  end
end
