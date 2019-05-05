require 'types/base_object'
require 'types/member_type'
require 'types/client_type'
require 'types/prefix_type'
require 'types/funder_type'

module Types
  class MutationType < BaseObject
    field :members, [MemberType], null: false

    def members
      Provider.query(nil)
    end

    field :clients, [ClientType], null: false

    def clients
      Client.query(nil)
    end

    field :prefixes, [PrefixType], null: false

    def prefixes
      Prefix.all
    end
  end
end
