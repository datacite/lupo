# frozen_string_literal: true

module Types
  class PeerReviewType < Types::BaseObject
    implements Types::DoiItem

    def type
      "PeerReview"
    end
  end
end
