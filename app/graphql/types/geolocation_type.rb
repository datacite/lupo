# frozen_string_literal: true

class GeolocationType < BaseObject
  description "Spatial region or named place where the data was gathered or about which the data is focused."

  field :geolocation_point,
        GeolocationPointType,
        null: true,
        hash_key: "geoLocationPoint",
        description: "A point location in space."
  field :geolocation_box,
        GeolocationBoxType,
        null: true,
        hash_key: "geoLocationBox",
        description: "The spatial limits of a box."
  field :geolocation_place,
        String,
        null: true,
        hash_key: "geoLocationPlace",
        description: "Description of a geographic location."
end
