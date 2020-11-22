# frozen_string_literal: true

class GeolocationPointType < BaseObject
  description "A point contains a single longitude-latitude pair."

  field :point_longitude,
        Float,
        null: true,
        hash_key: "pointLongitude",
        description: "Longitudinal dimension of point."
  field :point_latitude,
        Float,
        null: true,
        hash_key: "pointLatitude",
        description: "Latitudinal dimension of point."
end
