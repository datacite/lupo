# frozen_string_literal: true

module Types
  class JournalArticleType < Types::BaseObject
    implements Types::DoiItem

    def type
      "JournalArticle"
    end
  end
end
