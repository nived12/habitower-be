# frozen_string_literal: true

module ProgressLogs
  class Creator < ApplicationService
    attr_reader :membership, :group_step_id, :value, :note, :proof_url, :occurred_at

    def initialize(membership:, group_step_id:, value:, occurred_at:, note: nil, proof_url: nil)
      super()
      @membership = membership
      @group_step_id = group_step_id
      @value = value
      @occurred_at = occurred_at
      @note = note
      @proof_url = proof_url
    end

    def call
      group_step = membership.group.group_steps.kept.find_by(id: group_step_id)
      return failure("Group step not found") unless group_step

      log = membership.progress_logs.build(
        group_step_id: group_step.id,
        value: value,
        occurred_at: occurred_at,
        note: note,
        proof_url: proof_url
      )

      if log.save
        success(log)
      else
        failure(log.errors)
      end
    end
  end
end
