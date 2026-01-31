# frozen_string_literal: true

json.array!(@groups, partial: "api/v1/groups/group", as: :group)
