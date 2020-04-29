# frozen_string_literal: true

module Types
  class PreprintType < Types::BaseObject
    implements Types::DoiItem

    def type
      "Preprint"
    end
  end
end
