# frozen_string_literal: true

class MutationType < BaseObject
  field :create_claim, mutation: CreateClaim
  field :delete_claim, mutation: DeleteClaim
  field :update_user_profile, mutation: UpdateUserProfile
end
