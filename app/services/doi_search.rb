require "base64"

class DoiSearch < Bolognese::Metadata
  include Searchable

  include Cacheable

  include Dateable

  def self.cache_key(item)
    "doi_search/#{item.fetch('doi')}-#{item.fetch('updated')}"
  end

  def identifier
    doi_as_url(doi)
  end

  def xml
    Base64.encode64(raw)
  end

  def client
    cached_client_response(client_id.to_s.upcase)
  end

  # backwards compatibility
  def data_center
    client
  end

  def provider
    cached_provider_response(provider_id.to_s.upcase)
  end

  # backwards compatibility
  def member
    m = cached_member_response(provider_id.to_s.upcase)
    m[:data] if m.present?
  end

  def resource_type
    return nil unless resource_type_general.present?
    r = ResourceType.where(id: resource_type_general.downcase.underscore.dasherize)
    r[:data] if r.present?
  end

  def media

  end

  def updated_at
    date_updated
  end

  def metadata_version
    schema_version
  end

  def results
    related_identifiers.reduce({}) do |sum, i|
      k = i["relation-type-id"]
      v = sum[k].to_i + 1
      sum[k] = v
      sum
    end.map { |k,v| { id: k, title: k.underscore.humanize, count: v } }
      .sort { |a, b| b[:count] <=> a[:count] }
  end

  def related_identifiers
    []
  end
end
