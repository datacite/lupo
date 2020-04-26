# frozen_string_literal: true

class Types::PreprintType < Types::BaseObject
  implements Types::DoiItem

  def type
    "Preprint"
  end
end
