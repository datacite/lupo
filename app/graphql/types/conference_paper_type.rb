# frozen_string_literal: true

module Types
  class ConferencePaperType < Types::BaseObject
    implements Types::DoiItem

    def type
      "ConferencePaper"
    end
  end
end
