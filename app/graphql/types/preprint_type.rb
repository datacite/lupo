# frozen_string_literal: true

class PreprintType < BaseObject
  implements DoiItem

  def type
    "Preprint"
  end
end
