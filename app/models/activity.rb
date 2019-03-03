class Activity < Audited::Audit
  include Elasticsearch::Model

  # include helper module for Elasticsearch
  include Indexable

  delegate :uid, to: :doi
  
  alias_attribute :created, :created_at
  alias_attribute :doi_id, :uid

  belongs_to :doi, foreign_key: :auditable_id

  # use different index for testing
  index_name Rails.env.test? ? "activities-test" : "activities"

  mapping dynamic: 'false' do
    indexes :id,                             type: :keyword
    indexes :auditable_id,                   type: :keyword
    indexes :doi_id,                         type: :keyword
    indexes :uid,                            type: :keyword
    indexes :auditable_type,                 type: :keyword
    indexes :username,                       type: :keyword
    indexes :action,                         type: :keyword
    indexes :request_uuid,                   type: :keyword
    indexes :url,                            type: :text, fields: { keyword: { type: "keyword" }}
    indexes :creators,                       type: :object, properties: {
      nameType: { type: :keyword },
      nameIdentifiers: { type: :object, properties: {
        nameIdentifier: { type: :keyword },
        nameIdentifierScheme: { type: :keyword }
      }},
      name: { type: :text },
      givenName: { type: :text },
      familyName: { type: :text },
      affiliation: { type: :text }
    }
    indexes :contributors,                   type: :object, properties: {
      nameType: { type: :keyword },
      nameIdentifiers: { type: :object, properties: {
        nameIdentifier: { type: :keyword },
        nameIdentifierScheme: { type: :keyword }
      }},
      name: { type: :text },
      givenName: { type: :text },
      familyName: { type: :text },
      affiliation: { type: :text },
      contributorType: { type: :keyword }
    }
    indexes :titles,                         type: :object, properties: {
      title: { type: :text, fields: { keyword: { type: "keyword" }}},
      titleType: { type: :keyword },
      lang: { type: :keyword }
    }
    indexes :descriptions,                   type: :object, properties: {
      description: { type: :text },
      descriptionType: { type: :keyword },
      lang: { type: :keyword }
    }
    indexes :publisher,                      type: :text, fields: { keyword: { type: "keyword" }}
    indexes :publication_year,               type: :date, format: "yyyy", ignore_malformed: true
    indexes :client_id,                      type: :keyword
    indexes :provider_id,                    type: :keyword
    indexes :identifiers,                    type: :object, properties: {
      identifierType: { type: :keyword },
      identifier: { type: :keyword }
    }
    indexes :related_identifiers,            type: :object, properties: {
      relatedIdentifierType: { type: :keyword },
      relatedIdentifier: { type: :keyword },
      relationType: { type: :keyword },
      resourceTypeGeneral: { type: :keyword }
    }
    indexes :types,                          type: :object, properties: {
      resourceTypeGeneral: { type: :keyword },
      resourceType: { type: :keyword },
      schemaOrg: { type: :keyword },
      bibtex: { type: :keyword },
      citeproc: { type: :keyword },
      ris: { type: :keyword }
    }
    indexes :funding_references,             type: :object, properties: {
      funderName: { type: :keyword },
      funderIdentifier: { type: :keyword },
      funderIdentifierType: { type: :keyword },
      awardNumber: { type: :keyword },
      awardUri: { type: :keyword },
      awardTitle: { type: :keyword }
    }
    indexes :dates,                          type: :object, properties: {
      date: { type: :date, format: "yyyy-MM-dd||yyyy-MM||yyyy", ignore_malformed: true },
      dateType: { type: :keyword }
    }
    indexes :geo_locations,                  type: :object, properties: {
      geoLocationPoint: { type: :object },
      geoLocationBox: { type: :object },
      geoLocationPlace: { type: :keyword }
    }
    indexes :rights_list,                    type: :object, properties: {
      rights: { type: :keyword },
      rightsUri: { type: :keyword },
      lang: { type: :keyword }
    }
    indexes :subjects,                       type: :object, properties: {
      subject: { type: :keyword },
      subjectScheme: { type: :keyword },
      schemeUri: { type: :keyword },
      valueUri: { type: :keyword },
      lang: { type: :keyword }
    }
    indexes :container,                     type: :object, properties: {
      type: { type: :keyword },
      identifier: { type: :keyword },
      identifierType: { type: :keyword },
      title: { type: :keyword },
      volume: { type: :keyword },
      issue: { type: :keyword },
      firstPage: { type: :keyword },
      lastPage: { type: :keyword }
    }
    indexes :content_url,                    type: :keyword
    indexes :version_info,                   type: :keyword
    indexes :formats,                        type: :keyword
    indexes :sizes,                          type: :keyword
    indexes :language,                       type: :keyword
    indexes :aasm_state,                     type: :keyword
    indexes :schema_version,                 type: :keyword
    indexes :metadata_version,               type: :keyword
    indexes :source,                         type: :keyword
    indexes :landing_page, type: :object, properties: {
      checked: { type: :date, ignore_malformed: true },
      url: { type: :text, fields: { keyword: { type: "keyword" }}},
      status: { type: :integer },
      contentType: { type: :keyword },
      error: { type: :keyword },
      redirectCount: { type: :integer },
      redirectUrls: { type: :keyword },
      downloadLatency: { type: :scaled_float, scaling_factor: 100 },
      hasSchemaOrg: { type: :boolean },
      schemaOrgId: { type: :keyword },
      dcIdentifier: { type: :keyword },
      citationDoi: { type: :keyword },
      bodyHasPid: { type: :boolean }
    }
    indexes :created,                        type: :date, ignore_malformed: true

    # include parent objects
    indexes :doi,                            type: :object
  end

  def as_indexed_json(options={})
    {
      "id" => id,
      "auditable_id" => auditable_id,
      "doi_id" => doi_id,
      "uid" => uid,
      "auditable_type" => auditable_type,
      "username" => username,
      "action" => action,
      "request_uuid" => request_uuid,
      "url" => url,
      "creators" => creators,
      "contributors" => contributors,
      "titles" => titles,
      "descriptions" => descriptions,
      "publisher" => publisher,
      "client_id" => client_id,
      "provider_id" => provider_id,
      "types" => types,
      "identifiers" => identifiers,
      "related_identifiers" => related_identifiers,
      "funding_references" => funding_references,
      "publication_year" => publication_year,
      "dates" => dates,
      "geo_locations" => geo_locations,
      "rights_list" => rights_list,
      "container" => container,
      "content_url" => content_url,
      "version_info" => version_info,
      "formats" => formats,
      "sizes" => sizes,
      "language" => language,
      "subjects" => subjects,
      "landing_page" => landing_page,
      "aasm_state" => aasm_state,
      "schema_version" => schema_version,
      "metadata_version" => metadata_version,
      "source" => source,
      "created" => created,
      "doi" => doi.as_indexed_json
    }
  end

  def self.query_aggregations
    {}
  end

  def url
    audited_changes["url"]
  end

  def creators
    audited_changes["creators"]
  end

  def contributors
    audited_changes["contributors"]
  end

  def titles
    audited_changes["titles"]
  end

  def descriptions
    audited_changes["descriptions"]
  end

  def contributors
    audited_changes["contributors"]
  end

  def publisher
    audited_changes["publisher"]
  end

  def client_id
    audited_changes["client_id"]
  end

  def provider_id
    audited_changes["provider_id"]
  end

  def types
    audited_changes["types"]
  end

  def identifiers
    audited_changes["identifiers"]
  end

  def related_identifiers
    audited_changes["related_identifiers"]
  end

  def funding_references
    audited_changes["funding_references"]
  end

  def publication_year
    audited_changes["publication_year"]
  end

  def dates
    audited_changes["dates"]
  end

  def geo_locations
    audited_changes["geo_locations"]
  end

  def rights_list
    audited_changes["rights_list"]
  end

  def container
    audited_changes["container"]
  end

  def content_url
    audited_changes["content_url"]
  end

  def version_info
    audited_changes["version_info"]
  end

  def formats
    audited_changes["formats"]
  end

  def sizes
    audited_changes["sizes"]
  end

  def language
    audited_changes["language"]
  end

  def subjects
    audited_changes["subjects"]
  end

  def landing_page
    audited_changes["landing_page"]
  end

  def aasm_state
    audited_changes["aasm_state"]
  end

  def schema_version
    audited_changes["schema_version"]
  end

  def metadata_version
    audited_changes["metadata_version"]
  end

  def source
    audited_changes["source"]
  end

  def self.index_by_ids(options={})
    from_id = (options[:from_id] || 1).to_i
    until_id = (options[:until_id] || from_id + 499).to_i

    # get every id between from_id and end_id
    (from_id..until_id).step(500).each do |id|
      ActivityIndexByIdJob.perform_later(id: id)
    end

    (from_id..until_id).to_a.length
  end

  def self.index_by_id(options={})
    return nil unless options[:id].present?
    id = options[:id].to_i

    errors = 0
    count = 0

    logger = Logger.new(STDOUT)

    Activity.where(id: id..(id + 499)).find_in_batches(batch_size: 500) do |activities|
      response = Activity.__elasticsearch__.client.bulk \
        index:   Activity.index_name,
        type:    Activity.document_type,
        body:    activities.map { |activity| { index: { _id: activity.id, data: activity.as_indexed_json } } }

      # log errors
      errors += response['items'].map { |k, v| k.values.first['error'] }.compact.length
      response['items'].select { |k, v| k.values.first['error'].present? }.each do |err|
        logger.error "[Elasticsearch] " + err.inspect
      end

      count += activities.length
    end

    if errors > 1
      logger.error "[Elasticsearch] #{errors} errors indexing #{count} activities with IDs #{id} - #{(id + 499)}."
    elsif count > 0
      logger.info "[Elasticsearch] Indexed #{count} activities with IDs #{id} - #{(id + 499)}."
    end

    count
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => error
    logger.info "[Elasticsearch] Error #{error.message} indexing activities with IDs #{id} - #{(id + 499)}."

    count = 0

    Activity.where(id: id..(id + 499)).find_each do |activity|
      IndexJob.perform_later(activity)
      count += 1
    end

    logger.info "[Elasticsearch] Indexed #{count} activities with IDs #{id} - #{(id + 499)}."

    count
  end
end