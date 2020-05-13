# frozen_string_literal: true

class BookType < BaseObject
  implements DoiItem

  def type
    "Book"
  end
end
