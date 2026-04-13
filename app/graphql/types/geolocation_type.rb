# frozen_string_literal: true

class GeolocationType < BaseObject
  description "Spatial region or named place where the data was gathered or about which the data is focused."

  field :geolocation_point,
        GeolocationPointType,
        null: true,
        description: "A point location in space."

  def geolocation_point
    object["geoLocationPoint"]
  end

  field :geolocation_box,
        GeolocationBoxType,
        null: true,
        description: "The spatial limits of a box."

  def geolocation_box
    object["geoLocationBox"]
  end

  field :geolocation_place,
        String,
        null: true,
        description: "Description of a geographic location."

  def geolocation_place
    object["geoLocationPlace"]
  end
end
