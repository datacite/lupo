require "base64"

class DoiSearch < Bolognese::Metadata
  include Searchable

  def identifier
    doi_as_url(doi)
  end

  def xml
    Base64.encode64(raw)
  end

  # backwards compatibility
  def data_center
    client
  end

  # backwards compatibility
  def member
    m = cached_member_response(provider_id.to_s.upcase)
    m[:data] if m.present?
  end

  def media

  end

  def is_active
    "\x01"
  end

  def updated_at

  end

  def state
    is_active == "\x01" ? "searchable" : "hidden"
  end

  def client

  end

  def provider

  end

  def self.get_query_url(options={})
    if options[:id].present?
      params = { q: options[:id],
                 qf: "doi",
                 defType: "edismax",
                 wt: "json" }
    elsif options["doi-id"].present?
      params = { q: options['doi-id'],
                 qf: "doi",
                 fl: "doi,relatedIdentifier",
                 defType: "edismax",
                 wt: "json" }
    else
      if options[:ids].present?
        ids = options[:ids].split(",")[0..99]
        options[:query] = options[:query].to_s + " " + ids.join(" ")
        options[:qf] = "doi"
        options[:rows] = ids.length
        options[:sort] = "-created"
        options[:mm] = 1
      end

      if options[:sort].present?
        sort = case options[:sort]
               when "created" then "minted"
               when "-created" then "minted desc"
               when "published" then "publicationYear"
               when "-published" then "publicationYear desc"
               when "updated" then "updated"
               when "-updated" then "updated desc"
               else "score desc"
               end
      else
        sort = options[:query].present? ? "score desc" : "minted desc"
      end

      page = (options.dig(:page, :number) || 1).to_i
      per_page = (options.dig(:page, :size) || 25).to_i
      offset = (page - 1) * per_page

      created_date = options[:from_created_date].present? || options[:until_created_date].present?
      created_date = get_solr_date_range(options[:from_created_date], options[:until_created_date]) if created_date

      update_date = options[:from_update_date].present? || options[:until_update_date].present?
      update_date = get_solr_date_range(options[:from_update_date], options[:until_update_date]) if update_date
      registered = get_solr_date_range(options[:registered], options[:registered]) if options[:registered].present?

      fq = []
      fq << "resourceTypeGeneral:#{options[:resource_type_id].underscore.camelize}" if options[:resource_type_id].present?
      fq << "datacentre_symbol:#{options[:client_id].upcase}" if options[:client_id].present?
      fq << "allocator_symbol:#{options[:provider_id].upcase}" if options[:provider_id].present?
      fq << "nameIdentifier:ORCID\\:#{options[:person_id]}" if options[:person_id].present?
      fq << "minted:#{created_date}" if created_date
      fq << "updated:#{update_date}" if update_date
      fq << "minted:#{registered}" if registered
      fq << "publicationYear:#{options[:year]}" if options[:year].present?
      fq << "is_active:false" if options[:state] == "hidden"
      fq << "is_active:true" if options[:state] == "searchable"
      fq << "has_metadata:#{options[:has_metadata]}" if options[:has_metadata].present?
      fq << "schema_version:#{options[:schema_version]}" if options[:schema_version].present?

      params = { q: options.fetch(:query, nil).presence || "*:*",
                 start: offset,
                 rows: per_page,
                 fl: "doi,url,datacentre_symbol,allocator_symbol,xml,is_active,has_metadata,media,minted,updated",
                 qf: options[:qf],
                 fq: fq.join(" AND "),
                 facet: "true",
                 'facet.field' => %w(publicationYear datacentre_facet resourceType_facet schema_version is_active minted),
                 'facet.limit' => 15,
                 'facet.mincount' => 1,
                 'facet.range' => 'minted',
                 'f.minted.facet.range.start' => '2004-01-01T00:00:00Z',
                 'f.minted.facet.range.end' => '2024-01-01T00:00:00Z',
                 'f.minted.facet.range.gap' => '+1YEAR',
                 sort: sort,
                 defType: "edismax",
                 bq: "updated:[NOW/DAY-1YEAR TO NOW/DAY]",
                 mm: options[:mm],
                 wt: "json" }.compact
    end

    url + "?" + URI.encode_www_form(params)
  end

  def self.parse_data(result, options={})
    return result if result['errors']

    if options[:id].present?
      return nil if result.blank?

      items = result.body.fetch("data", {}).fetch('response', {}).fetch('docs', [])
      return [] if items.blank?

      item = items.first

      meta = result[:meta]

      resource_type = nil
      resource_type_id = item.fetch("resourceTypeGeneral", nil)
      resource_type = ResourceType.where(id: resource_type_id.downcase.underscore.dasherize) if resource_type_id.present?
      resource_type = resource_type[:data] if resource_type.present?

      client_id = item.fetch("datacentre_symbol", nil)
      client = cached_client_response(client_id)

      { data: parse_item(item), meta: meta }
    else
      if options[:doi_id].present?
        return { data: [], meta: [] } if result.blank?

        items = result.fetch("data", {}).fetch('response', {}).fetch('docs', [])
        return { data: [], meta: [] } if items.blank?

        item = items.first
        related_doi_identifiers = item.fetch('relatedIdentifier', [])
                                      .select { |id| id =~ /:DOI:.+/ }
                                      .map { |i| i.split(':', 3).last.strip.upcase }
        return { data: [], meta: [] } if related_doi_identifiers.blank?

        options = options.except(:doi_id)
        query_url = get_query_url(options.merge(ids: related_doi_identifiers.join(",")))
        result = Maremma.get(query_url, options)
      end

      items = result.body.fetch("data", {}).fetch("response", {}).fetch("docs", [])

      facets = result.body.fetch("data", {}).fetch("facet_counts", {})

      page = options[:page] || {}
      page[:number] = page[:number] && page[:number].to_i > 0 ? page[:number].to_i : 1
      page[:size] = page[:size] && (1..1000).include?(page[:size].to_i) ? page[:size].to_i : 25
      total = result.body.fetch("data", {}).fetch("response", {}).fetch("numFound", 0)
      total_pages = (total.to_f / page[:size]).ceil

      meta = parse_facet_counts(facets, options)
      meta = meta.merge(total: total, total_pages: total_pages, page: page[:number])

      clients = facets.fetch("facet_fields", {}).fetch("datacentre_facet", [])
                       .each_slice(2)
                       .map do |p|
                              id, title = p.first.split(' - ', 2)
                              [Client, { "id" => id, "name" => title }]
                            end
      clients = Array(clients).map { |item| parse_include(item.first, item.last) }

      { data: parse_items(items), meta: meta }
    end
  end

  def self.parse_item(item, options={})
    self.new(input: Base64.decode64(item.fetch("xml", "PGhzaD48L2hzaD4=\n")),
             from: "datacite",
             doi: item.fetch("doi", nil),
             sandbox: !Rails.env.production?,
             date_registered: item.fetch("minted", nil),
             date_updated: item.fetch("updated", nil),
             provider_id: item.fetch("allocator_symbol", nil),
             client_id: item.fetch("datacentre_symbol", nil),
             url: item.fetch("url", nil))
  end

  def self.parse_facet_counts(facets, options={})
    resource_types = facets.fetch("facet_fields", {}).fetch("resourceType_facet", [])
                           .each_slice(2)
                           .map { |k,v| { id: k.underscore.dasherize, title: k.underscore.humanize, count: v } }
    years = facets.fetch("facet_fields", {}).fetch("publicationYear", [])
                  .each_slice(2)
                  .sort { |a, b| b.first <=> a.first }
                  .map { |i| { id: i[0], title: i[0], count: i[1] } }
    registered = facets.fetch("facet_ranges", {}).fetch("minted", {}).fetch("counts", [])
                  .each_slice(2)
                  .sort { |a, b| b.first <=> a.first }
                  .map { |i| { id: i[0][0..3], title: i[0][0..3], count: i[1] } }
    clients = facets.fetch("facet_fields", {}).fetch("datacentre_facet", [])
                       .each_slice(2)
                       .map do |p|
                              id, title = p.first.split(' - ', 2)
                              [id, p.last]
                            end.to_h
    #clients = get_client_facets(clients)
    schema_versions = facets.fetch("facet_fields", {}).fetch("schema_version", [])
                            .each_slice(2)
                            .sort { |a, b| b.first <=> a.first }
                            .map { |i| { id: i[0], title: "Schema #{i[0]}", count: i[1] } }
    states = facets.fetch("facet_fields", {}).fetch("is_active", [])
                           .each_slice(2)
                           .map do |k,v|
                             id = (k == "true") ? "searchable" : "hidden"
                             { id: id, title: id.humanize, count: v }
                           end

    if options[:client_id].present? && clients.empty?
      clients = { options[:client_id] => 0 }
    end

    { "resource-types" => resource_types,
      "years" => years,
      "registered" => registered,
      # clients" => clients,
      "schema-versions" => schema_versions,
      "states" => states }
  end

  # def self.get_client_facets(clients, options={})
  #   response = Client.where(symbol: clients.keys.join(",").split(/\s*,\s*/))
  #
  #
  #   response.map { |p| { id: p.uid.downcase, name: p.name, count: clients.fetch(p.uid.upcase, 0) } }
  #           .sort { |a, b| b[:count] <=> a[:count] }
  # end

  def self.url
    "#{ENV["SOLR_URL"]}"
  end
end
