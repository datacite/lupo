# frozen_string_literal: true

module Types
  class BookChapterType < Types::BaseObject
    implements Types::DoiItem

    def type
      "BookChapter"
    end
  end
end
