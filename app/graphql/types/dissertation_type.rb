# frozen_string_literal: true

class Types::DissertationType < Types::BaseObject
  implements Types::DoiItem

  def type
    "Dissertation"
  end
end
