# frozen_string_literal: true

class GeolocationPointType < BaseObject
  description "A point contains a single longitude-latitude pair."

  field :point_longitude,
        Float,
        null: true,
        description: "Longitudinal dimension of point."

  def point_longitude
    object["pointLongitude"]
  end

  field :point_latitude,
        Float,
        null: true,
        description: "Latitudinal dimension of point."

  def point_latitude
    object["pointLatitude"]
  end
end
