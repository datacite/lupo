# frozen_string_literal: true

module Types
  class DissertationType < Types::BaseObject
    implements Types::DoiItem

    def type
      "Dissertation"
    end
  end
end
