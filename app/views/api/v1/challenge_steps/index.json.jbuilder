# frozen_string_literal: true

json.array!(@challenge_steps, partial: "api/v1/challenge_steps/challenge_step", as: :challenge_step)
