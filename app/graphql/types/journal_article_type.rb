# frozen_string_literal: true

class JournalArticleType < BaseObject
  implements DoiItem

  def type
    "JournalArticle"
  end
end
