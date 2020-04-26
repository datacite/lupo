# frozen_string_literal: true

class Types::BookChapterType < Types::BaseObject
  implements Types::DoiItem

  def type
    "BookChapter"
  end
end
