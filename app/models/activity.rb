class Activity < Audited::Audit
  include Elasticsearch::Model

  # include helper module for Elasticsearch
  include Indexable

  alias_attribute :created, :created_at
  alias_attribute :doi_id, :uid
  alias_attribute :changes, :audited_changes

  belongs_to :doi, foreign_key: :auditable_id

  def after_audit
    IndexJob.perform_later(self)
  end

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
    indexes :version,                        type: :keyword
    indexes :request_uuid,                   type: :keyword
    indexes :changes,                        type: :object, properties: {
      doi: { type: :keyword },
      url: { type: :text, fields: { keyword: { type: "keyword" }}},
      creators: { type: :object, properties: {
        nameType: { type: :keyword },
        nameIdentifiers: { type: :object, properties: {
          nameIdentifier: { type: :keyword },
          nameIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword }
        }},
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text },
        affiliation: { type: :text }
      }},
      contributors: { type: :object, properties: {
        nameType: { type: :keyword },
        nameIdentifiers: { type: :object, properties: {
          nameIdentifier: { type: :keyword },
          nameIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword }
        }},
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text },
        affiliation: { type: :text },
        contributorType: { type: :keyword }
      }},
      titles: { type: :object, properties: {
        title: { type: :text, fields: { keyword: { type: "keyword" }}},
        titleType: { type: :keyword },
        lang: { type: :keyword }
      }},
      descriptions: { type: :object, properties: {
        description: { type: :text },
        descriptionType: { type: :keyword },
        lang: { type: :keyword }
      }},
      publisher: { type: :text, fields: { keyword: { type: "keyword" }}},
      publication_year: { type: :date, format: "yyyy", ignore_malformed: true },
      client_id: { type: :keyword },
      provider_id: { type: :keyword },
      identifiers: { type: :object, properties: {
        identifierType: { type: :keyword },
        identifier: { type: :keyword }
      }},
      related_identifiers: { type: :object, properties: {
        relatedIdentifierType: { type: :keyword },
        relatedIdentifier: { type: :keyword },
        relationType: { type: :keyword },
        relatedMetadataScheme: { type: :keyword },
        schemeUri: { type: :keyword },
        schemeType: { type: :keyword },
        resourceTypeGeneral: { type: :keyword }
      }},
      types: { type: :object, properties: {
        resourceTypeGeneral: { type: :keyword },
        resourceType: { type: :keyword },
        schemaOrg: { type: :keyword },
        bibtex: { type: :keyword },
        citeproc: { type: :keyword },
        ris: { type: :keyword }
      }},
      funding_references: { type: :object, properties: {
        funderName: { type: :keyword },
        funderIdentifier: { type: :keyword },
        funderIdentifierType: { type: :keyword },
        awardNumber: { type: :keyword },
        awardUri: { type: :keyword },
        awardTitle: { type: :keyword }
      }},
      dates: { type: :object, properties: {
        date: { type: :date, format: "date_optional_time", ignore_malformed: true, fields: { raw: { type: :text }} },
        dateType: { type: :keyword }
      }},
      geo_locations: { type: :object, properties: {
        geoLocationPoint: { type: :object },
        geoLocationBox: { type: :object },
        geoLocationPlace: { type: :keyword }
      }},
      rights_list: { type: :object, properties: {
        rights: { type: :keyword },
        rightsUri: { type: :keyword },
        lang: { type: :keyword }
      }},
      subjects: { type: :object, properties: {
        subject: { type: :keyword },
        subjectScheme: { type: :keyword },
        schemeUri: { type: :keyword },
        valueUri: { type: :keyword },
        lang: { type: :keyword }
      }},
      container: { type: :object, properties: {
        type: { type: :keyword },
        identifier: { type: :keyword },
        identifierType: { type: :keyword },
        title: { type: :keyword },
        volume: { type: :keyword },
        issue: { type: :keyword },
        firstPage: { type: :keyword },
        lastPage: { type: :keyword }
      }},
      content_url: { type: :keyword },
      version_info: { type: :keyword },
      formats: { type: :keyword },
      sizes: { type: :keyword },
      language: { type: :keyword },
      aasm_state: { type: :keyword },
      schema_version: { type: :keyword },
      metadata_version: { type: :keyword },
      source: { type: :keyword },
      landing_page: { type: :object, properties: {
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
      }}
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
      "version" => version,
      "request_uuid" => request_uuid,
      "changes" => changes,
      "created" => created,
      "doi" => doi.present? ? doi.as_indexed_json : nil
    }
  end

  def self.query_aggregations
    {}
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

  def uid
    doi.present? ? doi.uid : changes.to_h['doi']
  end
end