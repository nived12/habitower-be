# frozen_string_literal: true

module Groups
  class StepCopier < ApplicationService
    attr_reader :group

    def initialize(group:)
      super()
      @group = group
    end

    def call
      templates = group.challenge_template.challenge_step_templates.kept.order(:position)
      return success(true) if templates.empty?

      now = Time.current
      rows = templates.map do |t|
        {
          group_id: group.id,
          creator_id: group.creator_id,
          title: t.title,
          position: t.position,
          requirements: t.requirements,
          original_step_id: t.id,
          created_at: now,
          updated_at: now,
        }
      end
      GroupStep.insert_all(rows)
      success(true)
    end
  end
end
