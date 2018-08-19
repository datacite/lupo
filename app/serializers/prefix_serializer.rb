class PrefixSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :dash
  set_type :prefixes
  set_id :prefix
  cache_options enabled: true, cache_length: 24.hours

  attributes :registration_agency, :created, :updated

  has_many :clients, if: Proc.new { |record| record.prefix != "10.5072" }
  has_many :providers, if: Proc.new { |record| record.prefix != "10.5072" }
end
