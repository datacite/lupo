# frozen_string_literal: true

class Types::JournalArticleType < Types::BaseObject
  implements Types::DoiItem

  def type
    "JournalArticle"
  end
end
