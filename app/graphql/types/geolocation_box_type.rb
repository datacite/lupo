# frozen_string_literal: true

class GeolocationBoxType < BaseObject
  description "A box is defined by two geographic points. Left low corner and right upper corner."

  field :west_bound_longitude,
        Float,
        null: false,
        hash_key: "westBoundLongitude",
        description: "Western longitudinal dimension of box."
  field :east_bound_longitude,
        Float,
        null: false,
        hash_key: "eastBoundLongitude",
        description: "Eastern longitudinal dimension of box."
  field :south_bound_latitude,
        Float,
        null: false,
        hash_key: "southBoundLatitude",
        description: "Southern latitudinal dimension of box."
  field :north_bound_latitude,
        Float,
        null: false,
        hash_key: "northBoundLatitude",
        description: "Northern latitudinal dimension of box."
end
