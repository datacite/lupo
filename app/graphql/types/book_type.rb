# frozen_string_literal: true

module Types
  class BookType < Types::BaseObject
    implements Types::DoiItem

    def type
      "Book"
    end
  end
end
