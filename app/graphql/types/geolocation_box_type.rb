# frozen_string_literal: true

class GeolocationBoxType < BaseObject
  description "A box is defined by two geographic points. Left low corner and right upper corner."

  field :west_bound_longitude,
        Float,
        null: false,
        description: "Western longitudinal dimension of box."

  def west_bound_longitude
    object["westBoundLongitude"]
  end

  field :east_bound_longitude,
        Float,
        null: false,
        description: "Eastern longitudinal dimension of box."

  def east_bound_longitude
    object["eastBoundLongitude"]
  end

  field :south_bound_latitude,
        Float,
        null: false,
        description: "Southern latitudinal dimension of box."

  def south_bound_latitude
    object["southBoundLatitude"]
  end

  field :north_bound_latitude,
        Float,
        null: false,
        description: "Northern latitudinal dimension of box."

  def north_bound_latitude
    object["northBoundLatitude"]
  end
end
