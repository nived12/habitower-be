# frozen_string_literal: true

json.array!(@challenges, partial: "api/v1/challenges/challenge", as: :challenge)
