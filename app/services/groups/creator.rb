# frozen_string_literal: true

module Groups
  class Creator
    INVITE_CODE_LENGTH = 6

    attr_reader :challenge, :creator, :privacy_type, :start_date

    def initialize(challenge:, creator:, privacy_type: "public", start_date: nil)
      @challenge = challenge
      @creator = creator
      @privacy_type = privacy_type
      @start_date = start_date
    end

    def call
      ActiveRecord::Base.transaction do
        group = build_group
        group.save!
        create_admin_membership(group)
        group
      end
    end

    private

    def build_group
      Group.new(
        challenge: challenge,
        creator: creator,
        privacy_type: privacy_type,
        start_date: calculated_start_date,
        invite_code: generate_invite_code,
      )
    end

    def calculated_start_date
      return start_date if start_date.present?

      if challenge.weekly?
        next_monday
      else
        next_month_start
      end
    end

    def next_monday
      today = Date.current
      days_until_monday = (1 - today.wday) % 7
      days_until_monday = 7 if days_until_monday.zero? && today.wday != 1
      days_until_monday = 0 if today.wday == 1

      today + days_until_monday.days
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
      return nil if privacy_type == "public"

      loop do
        code = SecureRandom.alphanumeric(INVITE_CODE_LENGTH).upcase
        break code unless Group.exists?(invite_code: code)
      end
    end

    def create_admin_membership(group)
      Membership.create!(
        group: group,
        user: creator,
        role: "admin",
      )
    end
  end
end
