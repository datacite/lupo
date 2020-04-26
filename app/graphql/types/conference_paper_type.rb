# frozen_string_literal: true

class Types::ConferencePaperType < Types::BaseObject
  implements Types::DoiItem

  def type
    "ConferencePaper"
  end
end
