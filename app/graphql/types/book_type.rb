# frozen_string_literal: true

class Types::BookType < Types::BaseObject
  implements Types::DoiItem

  def type
    "Book"
  end
end
