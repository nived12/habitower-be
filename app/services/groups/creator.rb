# frozen_string_literal: true

module Groups
  class Creator < ApplicationService
    INVITE_CODE_LENGTH = 6

    attr_reader :challenge_template, :creator, :privacy_type, :start_date, :title

    def initialize(challenge_template:, creator:, privacy_type: "public", start_date: nil, title: nil)
      super()
      @challenge_template = challenge_template
      @creator = creator
      @privacy_type = privacy_type
      @start_date = start_date
      @title = title.presence
    end

    def call
      group = build_group
      return failure(group.errors) unless group.valid?

      ActiveRecord::Base.transaction do
        group.save!
        group.memberships.create!(user: creator, role: "admin")
        Groups::StepCopier.call(group: group)
      end
      success(group)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record&.errors.presence || "Record invalid")
    end

    private

    def build_group
      Group.new(
        challenge_template: challenge_template,
        creator: creator,
        privacy_type: privacy_type,
        start_date: calculated_start_date,
        invite_code: generate_invite_code,
        title: title,
      )
    end

    def calculated_start_date
      return start_date if start_date.present?

      if challenge_template.weekly?
        next_monday
      else
        next_month_start
      end
    end

    def next_monday
      today = Date.current
      today.monday? ? today : today.next_occurring(:monday)
    end

    def next_month_start
      today = Date.current

      if today.day == 1
        today
      else
        today.next_month.beginning_of_month
      end
    end

    def generate_invite_code
      return if privacy_type == "public"

      loop do
        code = SecureRandom.alphanumeric(INVITE_CODE_LENGTH).upcase
        break code unless Group.exists?(invite_code: code)
      end
    end
  end
end
