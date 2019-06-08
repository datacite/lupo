class ObjectSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :objects
  
  attributes :subtype, :name, :author, :publisher, :periodical, :includedInDataCatalog, :version, :datePublished, :dateModified, :funder, :proxyIdentifiers, :registrantId

  attribute :subtype do |object|
    object.type
  end
end
