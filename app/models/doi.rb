class Doi < Base
  attr_reader :id, :doi, :identifier, :url, :author, :title, :container_title, :description, :resource_type_subtype, :client_id, :provider_id, :resource_type_id, :client, :provider, :resource_type, :license, :version, :results, :related_identifiers, :schema_version, :xml, :media, :published, :registered, :updated_at

  # include author methods
  include Authorable

  # include helper module for extracting identifier
  include Identifiable

  # include metadata helper methods
  include Metadatable

  # include helper module for caching infrequently changing resources
  include Cacheable

  # include helper module for date calculations
  include Dateable

  def initialize(attributes={}, options={})
    @id = attributes.fetch("doi", "").downcase.presence
    @doi = @id
    @identifier = attributes.fetch("id", nil).presence || doi_as_url(attributes.fetch("doi", nil))

    @xml = attributes.fetch('xml', "PGhzaD48L2hzaD4=\n")
    @media = attributes.fetch('media', nil)

    @author = attributes.fetch("author", nil)
    if author.nil?
      xml = Base64.decode64(@xml)
      xml = Hash.from_xml(xml).fetch("resource", {})
      authors = xml.fetch("creators", {}).fetch("creator", [])
      authors = [authors] if authors.is_a?(Hash)
      @author = get_hashed_authors(authors)
    end

    # get url registered in the handle system
    response = Maremma.head(@identifier, limit: 0)
    @url = response.headers.present? ? response.headers["location"] : nil

    @title = Doi.sanitize(attributes.fetch("title", []).first)
    @container_title = attributes.fetch("publisher", nil)
    @description = Doi.sanitize(attributes.fetch("description", []).first)
    @published = attributes.fetch("publicationYear", nil)
    @registered = attributes.fetch("minted", nil)
    @updated_at = attributes.fetch("updated", nil)
    @resource_type_subtype = attributes.fetch("resourceType", nil).presence || nil
    @license = normalize_license(attributes.fetch("rightsURI", []))
    @version = attributes.fetch("version", nil)
    @schema_version = attributes.fetch("schema_version", nil)
    @related_identifiers = attributes.fetch('relatedIdentifier', [])
      .select { |id| id =~ /:DOI:.+/ }
      .map do |i|
        relation_type, _related_identifier_type, related_identifier = i.split(':', 3)
        { "relation-type-id" => relation_type,
          "related-identifier" => doi_as_url(related_identifier.upcase) }
      end
    @results = @related_identifiers.reduce({}) do |sum, i|
      k = i["relation-type-id"]
      v = sum[k].to_i + 1
      sum[k] = v
      sum
    end.map { |k,v| { id: k, title: k.underscore.humanize, count: v } }
      .sort { |a, b| b[:count] <=> a[:count] }
    @client_id = attributes.fetch("datacentre_symbol", nil)
    @client_id = @client_id.downcase if @client_id.present?
    @provider_id = attributes.fetch("allocator_symbol", nil)
    @provider_id = @provider_id.downcase if @provider_id.present?
    @resource_type_id = attributes.fetch("resourceTypeGeneral", nil)
    @resource_type_id = @resource_type_id.underscore.dasherize if @resource_type_id.present?

    # associations
    @client = Array(options[:clients]).find { |p| p.id == @client_id }
    @provider = Array(options[:providers]).find { |r| r.id == @provider_id }
    @resource_type = Array(options[:resource_types]).find { |r| r.id == @resource_type_id }
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

      fq = %w(has_metadata:true is_active:true)
      fq << "resourceTypeGeneral:#{options[:resource_type_id].underscore.camelize}" if options[:resource_type_id].present?
      fq << "datacentre_symbol:#{options[:client_id].upcase}" if options[:client_id].present?
      fq << "allocator_symbol:#{options[:provider_id].upcase}" if options[:provider_id].present?
      fq << "nameIdentifier:ORCID\\:#{options[:person_id]}" if options[:person_id].present?
      fq << "minted:#{created_date}" if created_date
      fq << "updated:#{update_date}" if update_date
      fq << "minted:#{registered}" if registered
      fq << "publicationYear:#{options[:year]}" if options[:year].present?
      fq << "schema_version:#{options[:schema_version]}" if options[:schema_version].present?

      params = { q: options.fetch(:query, nil).presence || "*:*",
                 start: offset,
                 rows: per_page,
                 fl: "doi,title,description,publisher,publicationYear,resourceType,resourceTypeGeneral,rightsURI,version,datacentre_symbol,allocator_symbol,schema_version,xml,media,minted,updated",
                 qf: options[:qf],
                 fq: fq.join(" AND "),
                 facet: "true",
                 'facet.field' => %w(publicationYear datacentre_facet resourceType_facet schema_version minted),
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

  def self.get_data(options={})
    # sometimes don't query DataCite MDS
    return {} if (options[:client_id].present? && options[:client_id].exclude?("."))

    query_url = get_query_url(options)
    Maremma.get(query_url, options)
  end

  def self.parse_data(result, options={})
    return result if result['errors']

    if options[:id].present?
      return nil if result.blank?

      items = result.body.fetch("data", {}).fetch('response', {}).fetch('docs', [])
      return nil if items.blank?

      item = items.first

      meta = result[:meta]

      resource_type = nil
      resource_type_id = item.fetch("resourceTypeGeneral", nil)
      resource_type = ResourceType.where(id: resource_type_id.downcase.underscore.dasherize) if resource_type_id.present?
      resource_type = resource_type[:data] if resource_type.present?

      client_id = item.fetch("datacentre_symbol", nil)
      client = cached_client_response(client_id)

      { data: parse_item(item,
          resource_types: cached_resource_types,
          clients: [client],
          providers: cached_providers),
        meta: meta }
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

      { data: parse_items(items,
          resource_types: cached_resource_types,
          clients: clients,
          providers: cached_providers
          ),
        meta: meta }
    end
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
    clients = get_client_facets(clients)
    schema_versions = facets.fetch("facet_fields", {}).fetch("schema_version", [])
                            .each_slice(2)
                            .sort { |a, b| b.first <=> a.first }
                            .map { |i| { id: i[0], title: "Schema #{i[0]}", count: i[1] } }

    if options[:client_id].present? && clients.empty?
      clients = { options[:client_id] => 0 }
    end

    { "resource-types" => resource_types,
      "years" => years,
      "registered" => registered,
      "clients" => clients,
      "schema-versions" => schema_versions }
  end

  def self.get_client_facets(clients, options={})
    response = Client.where(symbol: clients.keys.join(",").split(/\s*,\s*/))


    response.map { |p| { id: p.uid.downcase, name: p.name, count: clients.fetch(p.uid.upcase, 0) } }
            .sort { |a, b| b[:count] <=> a[:count] }
  end

  def self.url
    "#{ENV["SOLR_HOST"]}"
  end

  # find Creative Commons or OSI license in rightsURI array
  def normalize_license(licenses)
    uri = licenses.map { |l| URI.parse(l) }.find { |l| l.host && l.host[/(creativecommons.org|opensource.org)$/] }
    return nil unless uri.present?

    # use HTTPS
    uri.scheme = "https"

    # use host name without subdomain
    uri.host = Array(/(creativecommons.org|opensource.org)/.match uri.host).last

    # normalize URLs
    if uri.host == "creativecommons.org"
      uri.path = uri.path.split('/')[0..-2].join("/") if uri.path.split('/').last == "legalcode"
      uri.path << '/' unless uri.path.end_with?('/')
    else
      uri.path = uri.path.gsub(/(-license|\.php|\.html)/, '')
      uri.path = uri.path.sub(/(mit|afl|apl|osl|gpl|ecl)/) { |match| match.upcase }
      uri.path = uri.path.sub(/(artistic|apache)/) { |match| match.titleize }
      uri.path = uri.path.sub(/([^0-9\-]+)(-)?([1-9])?(\.)?([0-9])?$/) do
        m = Regexp.last_match
        text = m[1]

        if m[3].present?
          version = [m[3], m[5].presence || "0"].join(".")
          [text, version].join("-")
        else
          text
        end
      end
    end

    uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
