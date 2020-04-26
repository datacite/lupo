# frozen_string_literal: true

class Types::PeerReviewType < Types::BaseObject
  implements Types::DoiItem

  def type
    "PeerReview"
  end
end
