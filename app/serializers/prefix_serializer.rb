class PrefixSerializer < ActiveModel::Serializer
  attributes :id, :created, :prefix, :version
end
