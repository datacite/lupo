require 'types/base_object'
require 'types/member_type'

module Types
  class MutationType < BaseObject
    field :members, [MemberType], null: false

    def members
      Provider.all
    end
  end
end
