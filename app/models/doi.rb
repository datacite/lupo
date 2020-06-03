require 'maremma'
require 'benchmark'

class Doi < ActiveRecord::Base
  audited only: [:doi, :url, :creators, :contributors, :titles, :publisher, :publication_year, :types, :descriptions, :container, :sizes, :formats, :version_info, :language, :dates, :identifiers, :related_identifiers, :funding_references, :geo_locations, :rights_list, :subjects, :schema_version, :content_url, :landing_page, :aasm_state, :source, :reason]

  include Metadatable
  include Cacheable
  include Licensable
  include Dateable

  # include helper module for generating random DOI suffixes
  include Helpable

  # include helper module for converting and exposing metadata
  include Crosscitable

  # include state machine
  include AASM

  # include helper module for Elasticsearch
  include Indexable

  # include helper module for sending emails
  include Mailable

  include Elasticsearch::Model

  aasm :whiny_transitions => false do
    # draft is initial state for new DOIs.
    state :draft, :initial => true
    state :tombstoned, :registered, :findable, :flagged, :broken

    event :register do
      transitions from: [:draft], to: :registered, if: [:registerable?]
    end

    event :publish do
      transitions from: [:draft], to: :findable, if: [:registerable?]
      transitions from: :registered, to: :findable
    end

    event :hide do
      transitions from: [:findable], to: :registered
    end

    event :show do
      transitions from: [:registered], to: :findable
    end

    event :flag do
      transitions from: [:registered, :findable], to: :flagged
    end

    event :link_check do
      transitions from: [:tombstoned, :registered, :findable, :flagged], to: :broken
    end
  end

  self.table_name = "dataset"
  alias_attribute :created_at, :created
  alias_attribute :updated_at, :updated
  alias_attribute :registered, :minted
  alias_attribute :state, :aasm_state

  attr_accessor :current_user

  attribute :regenerate, :boolean, default: false
  attribute :only_validate, :boolean, default: false
  attribute :should_validate, :boolean, default: false

  belongs_to :client, foreign_key: :datacentre
  has_many :media, -> { order "created DESC" }, foreign_key: :dataset, dependent: :destroy, inverse_of: :doi
  has_many :metadata, -> { order "created DESC" }, foreign_key: :dataset, dependent: :destroy, inverse_of: :doi
  has_many :view_events, -> { where target_relation_type_id: "views" }, class_name: "Event", primary_key: :doi, foreign_key: :target_doi, dependent: :destroy
  has_many :download_events, -> { where target_relation_type_id: "downloads" }, class_name: "Event", primary_key: :doi, foreign_key: :target_doi, dependent: :destroy
  has_many :reference_events, -> { where source_relation_type_id: "references" }, class_name: "Event", primary_key: :doi, foreign_key: :source_doi, dependent: :destroy
  has_many :citation_events, -> { where target_relation_type_id: "citations" }, class_name: "Event", primary_key: :doi, foreign_key: :target_doi, dependent: :destroy
  has_many :part_events, -> { where source_relation_type_id: "parts" }, class_name: "Event", primary_key: :doi, foreign_key: :source_doi, dependent: :destroy
  has_many :part_of_events, -> { where target_relation_type_id: "part_of" }, class_name: "Event", primary_key: :doi, foreign_key: :target_doi, dependent: :destroy
  has_many :version_events, -> { where source_relation_type_id: "versions" }, class_name: "Event", primary_key: :doi, foreign_key: :source_doi, dependent: :destroy
  has_many :version_of_events, -> { where target_relation_type_id: "version_of" }, class_name: "Event", primary_key: :doi, foreign_key: :target_doi, dependent: :destroy
  has_many :activities, as: :auditable, dependent: :destroy
  # has_many :source_events, class_name: "Event", primary_key: :doi, foreign_key: :source_doi, dependent: :destroy
  # has_many :target_events, class_name: "Event", primary_key: :doi, foreign_key: :target_doi, dependent: :destroy

  has_many :references, class_name: "Doi", through: :reference_events, source: :doi_for_target
  has_many :citations, class_name: "Doi", through: :citation_events, source: :doi_for_source
  has_many :parts, class_name: "Doi", through: :part_events, source: :doi_for_target
  has_many :part_of, class_name: "Doi", through: :part_of_events, source: :doi_for_source
  has_many :versions, class_name: "Doi", through: :version_events, source: :doi_for_target
  has_many :version_of, class_name: "Doi", through: :version_of_events, source: :doi_for_source

  delegate :provider, to: :client, allow_nil: true
  delegate :consortium_id, to: :provider, allow_nil: true

  validates_presence_of :doi
  validates_presence_of :url, if: Proc.new { |doi| doi.is_registered_or_findable? }

  # from https://www.crossref.org/blog/dois-and-matching-regular-expressions/ but using uppercase
  validates_format_of :doi, with: /\A10\.\d{4,5}\/[-\._;()\/:a-zA-Z0-9\*~\$\=]+\z/, on: :create
  validates_format_of :url, with: /\A(ftp|http|https):\/\/[\S]+/, if: :url?, message: "URL is not valid"
  validates_uniqueness_of :doi, message: "This DOI has already been taken", unless: :only_validate
  validates_inclusion_of :agency, :in => %w( DataCite Crossref KISTI mEDRA ISTIC JaLC Airiti CNKI OP), allow_blank: true
  validates :last_landing_page_status, numericality: { only_integer: true }, if: :last_landing_page_status?
  validates :xml, presence: true, xml_schema: true, if: Proc.new { |doi| doi.validatable? }
  validate :check_dates, if: :dates?
  validate :check_rights_list, if: :rights_list?
  validate :check_titles, if: :titles?
  validate :check_descriptions, if: :descriptions?
  validate :check_types, if: :types?
  validate :check_container, if: :container?
  validate :check_subjects, if: :subjects?
  validate :check_creators, if: :creators?
  validate :check_contributors, if: :contributors?
  validate :check_landing_page, if: :landing_page?
  validate :check_identifiers, if: :identifiers?
  validate :check_related_identifiers, if: :related_identifiers?
  validate :check_funding_references, if: :funding_references?
  validate :check_geo_locations, if: :geo_locations?

  after_commit :update_url, on: [:create, :update]
  after_commit :update_media, on: [:create, :update]

  before_validation :update_xml, if: :regenerate
  before_save :set_defaults, :save_metadata
  before_create { self.created = Time.zone.now.utc.iso8601 }

  scope :q, ->(query) { where("dataset.doi = ?", query) }

  # use different index for testing
  if Rails.env.test?
    index_name "dois-test"
  elsif ENV["ES_PREFIX"].present?
    index_name"dois-#{ENV["ES_PREFIX"]}"
  else
    index_name "dois"
  end

  settings index: {
    analysis: {
      analyzer: {
        string_lowercase: { tokenizer: 'keyword', filter: %w(lowercase ascii_folding) },
      },
      normalizer: {
        keyword_lowercase: { type: "custom", filter: %w(lowercase) },
      },
      filter: {
        ascii_folding: { type: 'asciifolding', preserve_original: true },
      }
    }
  } do
    mapping dynamic: 'false' do
      indexes :id,                             type: :keyword
      indexes :uid,                            type: :keyword, normalizer: "keyword_lowercase"
      indexes :doi,                            type: :keyword
      indexes :identifier,                     type: :keyword
      indexes :url,                            type: :text, fields: { keyword: { type: "keyword" }}
      indexes :creators,                       type: :object, properties: {
        nameType: { type: :keyword },
        nameIdentifiers: { type: :object, properties: {
          nameIdentifier: { type: :keyword },
          nameIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword }
        }},
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text },
        affiliation: { type: :object, properties: {
          name: { type: :keyword },
          affiliationIdentifier: { type: :keyword },
          affiliationIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword }
        }},
      }
      indexes :contributors, type: :object, properties: {
        nameType: { type: :keyword },
        nameIdentifiers: { type: :object, properties: {
          nameIdentifier: { type: :keyword },
          nameIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        }},
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text },
        affiliation: { type: :object, properties: {
          name: { type: :keyword },
          affiliationIdentifier: { type: :keyword },
          affiliationIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword }
        }},
        contributorType: { type: :keyword }
      }
      indexes :creator_names,                  type: :text
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
      indexes :consortium_id,                  type: :keyword
      indexes :resource_type_id,               type: :keyword
      indexes :affiliation_id,                 type: :keyword
      indexes :client_id_and_name,             type: :keyword
      indexes :provider_id_and_name,           type: :keyword
      indexes :resource_type_id_and_name,      type: :keyword
      indexes :affiliation_id_and_name,        type: :keyword
      indexes :media_ids,                      type: :keyword
      indexes :media,                          type: :object, properties: {
        type: { type: :keyword },
        id: { type: :keyword },
        uid: { type: :keyword },
        url: { type: :text },
        media_type: { type: :keyword },
        version: { type: :keyword },
        created: { type: :date, ignore_malformed: true },
        updated: { type: :date, ignore_malformed: true }
      }
      indexes :identifiers,                    type: :object, properties: {
        identifierType: { type: :keyword },
        identifier: { type: :keyword, normalizer: "keyword_lowercase" },
      }
      indexes :related_identifiers,            type: :object, properties: {
        relatedIdentifierType: { type: :keyword },
        relatedIdentifier: { type: :keyword, normalizer: "keyword_lowercase" },
        relationType: { type: :keyword },
        relatedMetadataScheme: { type: :keyword },
        schemeUri: { type: :keyword },
        schemeType: { type: :keyword },
        resourceTypeGeneral: { type: :keyword },
      }
      indexes :types,                          type: :object, properties: {
        resourceTypeGeneral: { type: :keyword },
        resourceType: { type: :keyword },
        schemaOrg: { type: :keyword },
        bibtex: { type: :keyword },
        citeproc: { type: :keyword },
        ris: { type: :keyword },
      }
      indexes :funding_references,             type: :object, properties: {
        funderName: { type: :keyword },
        funderIdentifier: { type: :keyword, normalizer: "keyword_lowercase" },
        funderIdentifierType: { type: :keyword },
        awardNumber: { type: :keyword },
        awardUri: { type: :keyword },
        awardTitle: { type: :keyword }
      }
      indexes :dates,                          type: :object, properties: {
        date: { type: :text },
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
        subjectScheme: { type: :keyword },
        subject: { type: :keyword },
        schemeUri: { type: :keyword },
        valueUri: { type: :keyword },
        lang: { type: :keyword },
      }
      indexes :container,                     type: :object, properties: {
        type: { type: :keyword },
        identifier: { type: :keyword, normalizer: "keyword_lowercase" },
        identifierType: { type: :keyword },
        title: { type: :keyword },
        volume: { type: :keyword },
        issue: { type: :keyword },
        firstPage: { type: :keyword },
        lastPage: { type: :keyword }
      }

      indexes :xml,                            type: :text, index: "false"
      indexes :content_url,                    type: :keyword
      indexes :version_info,                   type: :keyword
      indexes :formats,                        type: :keyword
      indexes :sizes,                          type: :keyword
      indexes :language,                       type: :keyword
      indexes :is_active,                      type: :keyword
      indexes :aasm_state,                     type: :keyword
      indexes :schema_version,                 type: :keyword
      indexes :metadata_version,               type: :keyword
      indexes :agency,                         type: :keyword
      indexes :source,                         type: :keyword
      indexes :prefix,                         type: :keyword
      indexes :suffix,                         type: :keyword
      indexes :reason,                         type: :text
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
      indexes :cache_key,                      type: :keyword
      indexes :registered,                     type: :date, ignore_malformed: true
      indexes :published,                      type: :date, ignore_malformed: true
      indexes :created,                        type: :date, ignore_malformed: true
      indexes :updated,                        type: :date, ignore_malformed: true

      # include parent objects
      indexes :client,                         type: :object, properties: {
        id: { type: :keyword },
        uid: { type: :keyword, normalizer: "keyword_lowercase" },
        symbol: { type: :keyword },
        provider_id: { type: :keyword },
        re3data_id: { type: :keyword },
        opendoar_id: { type: :keyword },
        salesforce_id: { type: :keyword },
        prefix_ids: { type: :keyword },
        name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true }} },
        alternate_name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true }} },
        description: { type: :text },
        language: { type: :keyword },
        client_type: { type: :keyword },
        repository_type: { type: :keyword },
        certificate: { type: :keyword },
        system_email: { type: :text, fields: { keyword: { type: "keyword" }} },
        version: { type: :integer },
        is_active: { type: :keyword },
        domains: { type: :text },
        year: { type: :integer },
        url: { type: :text, fields: { keyword: { type: "keyword" }} },
        software: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true }} },
        cache_key: { type: :keyword },
        created: { type: :date },
        updated: { type: :date },
        deleted_at: { type: :date },
        cumulative_years: { type: :integer, index: "false" }
      }
      indexes :provider,                       type: :object, properties: {
        id: { type: :keyword },
        uid: { type: :keyword, normalizer: "keyword_lowercase" },
        symbol: { type: :keyword },
        client_ids: { type: :keyword },
        prefix_ids: { type: :keyword },
        name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }} },
        display_name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }} },
        system_email: { type: :text, fields: { keyword: { type: "keyword" }} },
        group_email: { type: :text, fields: { keyword: { type: "keyword" }} },
        version: { type: :integer },
        is_active: { type: :keyword },
        year: { type: :integer },
        description: { type: :text },
        website: { type: :text, fields: { keyword: { type: "keyword" }} },
        logo_url: { type: :text },
        region: { type: :keyword },
        focus_area: { type: :keyword },
        organization_type: { type: :keyword },
        member_type: { type: :keyword },
        consortium_id: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true }} },
        consortium_organization_ids: { type: :keyword },
        country_code: { type: :keyword },
        role_name: { type: :keyword },
        cache_key: { type: :keyword },
        joined: { type: :date },
        twitter_handle: { type: :keyword },
        ror_id: { type: :keyword },
        salesforce_id: { type: :keyword },
        billing_information: { type: :object, properties: {
          postCode: { type: :keyword },
          state: { type: :text},
          organization: { type: :text},
          department: { type: :text},
          city: { type: :text },
          country: { type: :text },
          address: { type: :text }
        } },
        technical_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text},
          family_name: { type: :text },
        } },
        secondary_technical_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text},
          family_name: { type: :text },
        } },
        billing_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text},
          family_name: { type: :text },
        } },
        secondary_billing_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        service_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        secondary_service_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        voting_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        created: { type: :date },
        updated: { type: :date },
        deleted_at: { type: :date },
        cumulative_years: { type: :integer, index: "false" },
        consortium: { type: :object },
        consortium_organizations: { type: :object },
      }
      indexes :resource_type, type: :object
      indexes :view_count, type: :integer
      indexes :download_count, type: :integer
      indexes :reference_count, type: :integer
      indexes :citation_count, type: :integer
      indexes :part_count, type: :integer
      indexes :part_of_count, type: :integer
      indexes :version_count, type: :integer
      indexes :version_of_count, type: :integer
      indexes :views_over_time, type: :object
      indexes :downloads_over_time, type: :object
      indexes :citations_over_time, type: :object
      indexes :part_ids, type: :keyword
      indexes :part_of_ids, type: :keyword
      indexes :version_ids, type: :keyword
      indexes :version_of_ids, type: :keyword
      indexes :reference_ids, type: :keyword
      indexes :citation_ids, type: :keyword
    end
  end

  def as_indexed_json(options={})
    {
      "id" => uid,
      "uid" => uid,
      "doi" => doi,
      "identifier" => identifier,
      "url" => url,
      "creators" => Array.wrap(creators),
      "contributors" => Array.wrap(contributors),
      "creator_names" => creator_names,
      "titles" => Array.wrap(titles),
      "descriptions" => Array.wrap(descriptions),
      "publisher" => publisher,
      "client_id" => client_id,
      "provider_id" => provider_id,
      "consortium_id" => consortium_id,
      "resource_type_id" => resource_type_id,
      "client_id_and_name" => client_id_and_name,
      "provider_id_and_name" => provider_id_and_name,
      "resource_type_id_and_name" => resource_type_id_and_name,
      "affiliation_id" => affiliation_id,
      "affiliation_id_and_name" => affiliation_id_and_name,
      "media_ids" => media_ids,
      "view_count" => view_count,
      "views_over_time" => views_over_time,
      "download_count" => download_count,
      "downloads_over_time" => downloads_over_time,
      "citation_count" => citation_count,
      "citations_over_time" => citations_over_time,
      "reference_count" => reference_count,
      "part_count" => part_count,
      "part_of_count" => part_of_count,
      "version_count" => version_count,
      "version_of_count" => version_of_count,
      "prefix" => prefix,
      "suffix" => suffix,
      "types" => types,
      "identifiers" => identifiers,
      "related_identifiers" => Array.wrap(related_identifiers),
      "funding_references" => Array.wrap(funding_references),
      "publication_year" => publication_year,
      "dates" => dates,
      "geo_locations" => Array.wrap(geo_locations),
      "rights_list" => Array.wrap(rights_list),
      "container" => container,
      "content_url" => content_url,
      "version_info" => version_info,
      "formats" => Array.wrap(formats),
      "sizes" => Array.wrap(sizes),
      "language" => language,
      "subjects" => Array.wrap(subjects),
      "xml" => xml,
      "is_active" => is_active,
      "landing_page" => landing_page,
      "agency" => agency,
      "aasm_state" => aasm_state,
      "schema_version" => schema_version,
      "metadata_version" => metadata_version,
      "reason" => reason,
      "source" => source,
      "cache_key" => cache_key,
      "registered" => registered,
      "created" => created,
      "updated" => updated,
      "published" => published,
      "client" => client.try(:as_indexed_json, exclude_associations: true),
      "provider" => provider.try(:as_indexed_json, exclude_associations: true),
      "resource_type" => resource_type.try(:as_indexed_json),
      "media" => media.map { |m| m.try(:as_indexed_json) },
      "reference_ids" => reference_ids,
      "citation_ids" => citation_ids,
      "part_ids" => part_ids,
      "part_of_ids" => part_of_ids,
      "version_ids" => version_ids,
      "version_of_ids" => version_of_ids,
    }
  end

  def self.query_aggregations
    {
      resource_types: { terms: { field: 'resource_type_id_and_name', size: 16, min_doc_count: 1 } },
      states: { terms: { field: 'aasm_state', size: 3, min_doc_count: 1 } },
      years: {
        # filter: {
        #   range: {
        #     "publication_year": {
        #       "gte": "2000"
        #     }
        #   }
        # },
        # aggs: {
        #   published: {
            date_histogram: {
              field: 'publication_year',
              interval: 'year',
              format: 'year',
              order: {
                _key: "desc"
              },
              min_doc_count: 1
            },
            # aggs: {
            #   bucket_truncate: {
            #     bucket_sort: {
            #       size: 10
            #     }
            #   }
            # }
        #   }
        # }
      },
      registration_agencies: { terms: { field: 'agency', size: 10, min_doc_count: 1 } },
      created: { date_histogram: { field: 'created', interval: 'year', format: 'year', order: { _key: "desc" }, min_doc_count: 1 },
                 aggs: { bucket_truncate: { bucket_sort: { size: 10 } } } },
      registered: { date_histogram: { field: 'registered', interval: 'year', format: 'year', order: { _key: "desc" }, min_doc_count: 1 },
                    aggs: { bucket_truncate: { bucket_sort: { size: 10 } } } },
      providers: { terms: { field: 'provider_id_and_name', size: 10, min_doc_count: 1} },
      clients: { terms: { field: 'client_id_and_name', size: 10, min_doc_count: 1 } },
      affiliations: { terms: { field: 'affiliation_id_and_name', size: 10, min_doc_count: 1 } },
      prefixes: { terms: { field: 'prefix', size: 10, min_doc_count: 1 } },
      schema_versions: { terms: { field: 'schema_version', size: 10, min_doc_count: 1 } },
      link_checks_status: { terms: { field: 'landing_page.status', size: 10, min_doc_count: 1 } },
      # link_checks_has_schema_org: { terms: { field: 'landing_page.hasSchemaOrg', size: 2, min_doc_count: 1 } },
      # link_checks_schema_org_id: { value_count: { field: "landing_page.schemaOrgId" } },
      # link_checks_dc_identifier: { value_count: { field: "landing_page.dcIdentifier" } },
      # link_checks_citation_doi: { value_count: { field: "landing_page.citationDoi" } },
      # links_checked: { value_count: { field: "landing_page.checked" } },
      # sources: { terms: { field: 'source', size: 15, min_doc_count: 1 } },
      subjects: { terms: { field: 'subjects.subject', size: 10, min_doc_count: 1 } },
      pid_entities: {
        filter: { term: { "subjects.subjectScheme": "PidEntity" } },
        aggs: {
          subject: { terms: { field: 'subjects.subject', size: 10, min_doc_count: 1,
            include: %w(Dataset Publication Software Organization Funder Person Grant Sample Instrument Repository Project) } },
        },
      },
      fields_of_science: {
        filter: { term: { "subjects.subjectScheme": "Fields of Science and Technology (FOS)" } },
        aggs: {
          subject: { terms: { field: 'subjects.subject', size: 10, min_doc_count: 1,
            include: "FOS:.*" } },
        },
      },
      certificates: { terms: { field: 'client.certificate', size: 10, min_doc_count: 1 } },
      views: {
        date_histogram: { field: 'publication_year', interval: 'year', format: 'year', order: { _key: "desc" }, min_doc_count: 1 },
        aggs: {
          metric_count: { sum: { field: "view_count" } },
          bucket_truncate: { bucket_sort: { size: 10 } },
        },
      },
      downloads: {
        date_histogram: { field: 'publication_year', interval: 'year', format: 'year', order: { _key: "desc" }, min_doc_count: 1 },
        aggs: {
          metric_count: { sum: { field: "download_count" } },
          bucket_truncate: { bucket_sort: { size: 10 } },
        },
      },
      citations: {
        date_histogram: { field: 'publication_year', interval: 'year', format: 'year', order: { _key: "desc" }, min_doc_count: 1 },
        aggs: {
          metric_count: { sum: { field: "citation_count" } },
          bucket_truncate: { bucket_sort: { size: 10 } },
        },
      },
    }
  end

  def self.provider_aggregations
    { providers_totals: { terms: { field: 'provider_id', size: ::Provider.__elasticsearch__.count, min_doc_count: 1 }, aggs: sub_aggregations} }
  end

  def self.client_aggregations
    { clients_totals: { terms: { field: 'client_id', size: ::Client.__elasticsearch__.count, min_doc_count: 1 }, aggs: sub_aggregations } }
  end

  def self.client_export_aggregations
    { clients_totals: { terms: { field: 'client_id', size: ::Client.__elasticsearch__.count, min_doc_count: 1 }, aggs: export_sub_aggregations } }
  end

  def self.prefix_aggregations
    { prefixes_totals: { terms: { field: 'prefix', size: ::Prefix.count, min_doc_count: 1 }, aggs: sub_aggregations } }
  end

  def self.sub_aggregations
    {
      states: { terms: { field: 'aasm_state', size: 4, min_doc_count: 1 } },
      this_month: { date_range: { field: 'created', ranges: { from: "now/M", to: "now/d" } } },
      this_year: { date_range: { field: 'created', ranges: { from: "now/y", to: "now/d" } } },
      last_year: { date_range: { field: 'created', ranges: { from: "now-1y/y", to: "now/y-1d" } } },
      two_years_ago: { date_range: { field: 'created', ranges: { from: "now-2y/y", to: "now-1y/y-1d" } } }
    }
  end

  def self.export_sub_aggregations
    {
      this_year: { date_range: { field: 'created', ranges: { from: "now/y", to: "now/d" } } },
      last_year: { date_range: { field: 'created', ranges: { from: "now-1y/y", to: "now/y-1d" } } },
      two_years_ago: { date_range: { field: 'created', ranges: { from: "now-2y/y", to: "now-1y/y-1d" } } }
    }
  end

  def self.query_fields
    ["uid^50", "related_identifiers.relatedIdentifier^3", 'titles.title^3', 'creator_names^3', 'creators.id^3', 'publisher^3', 'descriptions.description^3', 'subjects.subject^3']
  end

  # return results for one or more ids
  def self.find_by_ids(ids, options={})
    ids = ids.split(",") if ids.is_a?(String)

    options[:page] ||= {}
    options[:page][:number] ||= 1
    options[:page][:size] ||= 1000
    options[:sort] ||= { created: { order: "asc" }}

    must = [{ terms: { doi: ids.map(&:upcase) }}]
    must << { terms: { aasm_state: options[:state].to_s.split(",") }} if options[:state].present?
    must << { terms: { provider_id: options[:provider_id].split(",") }} if options[:provider_id].present?
    must << { terms: { client_id: options[:client_id].to_s.split(",") }} if options[:client_id].present?

    __elasticsearch__.search({
      from: (options.dig(:page, :number) - 1) * options.dig(:page, :size),
      size: options.dig(:page, :size),
      sort: [options[:sort]],
      query: {
        bool: {
          must: must,
        }
      },
      aggregations: query_aggregations,
    })
  end

  # return results for one doi
  def self.find_by_id(id)
    __elasticsearch__.search(
      query: {
        match: {
          uid: id,
        },
      },
    )
  end

  def self.stats_query(options={})
    filter = []
    filter << { term: { provider_id: options[:provider_id] } } if options[:provider_id].present?
    filter << { term: { client_id: options[:client_id] } } if options[:client_id].present?
    filter << { term: { consortium_id: options[:consortium_id].upcase }} if options[:consortium_id].present?
    filter << { term: { "creators.nameIdentifiers.nameIdentifier" => "https://orcid.org/#{orcid_from_url(options[:user_id])}" }} if options[:user_id].present?

    aggregations = {
      created: { date_histogram: { field: 'created', interval: 'year', format: 'year', order: { _key: "desc" }, min_doc_count: 1 },
                 aggs: { bucket_truncate: { bucket_sort: { size: 12 } } } },
    }

    __elasticsearch__.search({
      query: {
        bool: {
          must: [{ match_all: {} }],
          filter: filter,
        }
      },
      aggregations: aggregations,
    })
  end

  def self.query(query, options={})
    # support scroll api
    # map function is small performance hit
    if options[:scroll_id].present? && options.dig(:page, :scroll)
      begin
        response = __elasticsearch__.client.scroll(body:
          { scroll_id: options[:scroll_id],
            scroll: options.dig(:page, :scroll)
          })
        return Hashie::Mash.new({
            total: response.dig("hits", "total", "value"),
            results: response.dig("hits", "hits").map { |r| r["_source"] },
            scroll_id: response["_scroll_id"]
          })
      # handle expired scroll_id (Elasticsearch returns this error)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        return Hashie::Mash.new({
          total: 0,
          results: [],
          scroll_id: nil
        })
      end
    end

    options[:page] ||= {}
    options[:page][:number] ||= 1
    options[:page][:size] ||= 25

    if options[:totals_agg] == "provider"
      aggregations = provider_aggregations
    elsif options[:totals_agg] == "client"
      aggregations = client_aggregations
    elsif options[:totals_agg] == "client_export"
      aggregations = client_export_aggregations
    elsif options[:totals_agg] == "prefix"
      aggregations = prefix_aggregations
    else
      aggregations = query_aggregations
    end

    # Cursor nav uses search_after, this should always be an array of values that match the sort.
    if options.dig(:page, :cursor)
      from = 0

      # make sure we have a valid cursor
      search_after = options.dig(:page, :cursor).is_a?(Array) ? options.dig(:page, :cursor) : [1, "1"]
      sort = [{ created: "asc", uid: "asc" }]
    else
      from = ((options.dig(:page, :number) || 1) - 1) * (options.dig(:page, :size) || 25)
      search_after = nil
      sort = options[:sort]
    end

    # make sure field name uses underscore
    # escape forward slashes in query
    if query.present?
      query = query.gsub(/publicationYear/, "publication_year")
      query = query.gsub(/relatedIdentifiers/, "related_identifiers")
      query = query.gsub(/rightsList/, "rights_list")
      query = query.gsub(/fundingReferences/, "funding_references")
      query = query.gsub(/geoLocations/, "geo_locations")
      query = query.gsub(/landingPage/, "landing_page")
      query = query.gsub(/contentUrl/, "content_url")
      query = query.gsub("/", '\/')
    end

    # turn ids into an array if provided as comma-separated string
    options[:ids] = options[:ids].split(",") if options[:ids].is_a?(String)

    if query.present?
      must = [{ query_string: { query: query, fields: query_fields, default_operator: "AND", phrase_slop: 1 } }]
    else
      must = [{ match_all: {} }]
    end

    must_not = []
    filter = []

    filter << { terms: { doi: options[:ids].map(&:upcase) }} if options[:ids].present?
    filter << { term: { "types.resourceTypeGeneral": options[:resource_type_id].underscore.camelize }} if options[:resource_type_id].present?
    filter << { terms: { "types.resourceType": options[:resource_type].split(",") }} if options[:resource_type].present?
    filter << { terms: { provider_id: options[:provider_id].split(",") } } if options[:provider_id].present?
    filter << { terms: { client_id: options[:client_id].to_s.split(",") } } if options[:client_id].present?
    filter << { terms: { prefix: options[:prefix].to_s.split(",") } } if options[:prefix].present?
    filter << { term: { uid: options[:uid] }} if options[:uid].present?
    filter << { range: { created: { gte: "#{options[:created].split(",").min}||/y", lte: "#{options[:created].split(",").max}||/y", format: "yyyy" }}} if options[:created].present?
    filter << { term: { schema_version: "http://datacite.org/schema/kernel-#{options[:schema_version]}" }} if options[:schema_version].present?
    filter << { terms: { "subjects.subject": options[:subject].split(",") } } if options[:subject].present?
    if options[:pid_entity].present?
      filter << { term: { "subjects.subjectScheme": "PidEntity" } }
      filter << { terms: { "subjects.subject": options[:pid_entity].split(",") } }
    end
    if options[:field_of_science].present?
      filter << { term: { "subjects.subjectScheme": "Fields of Science and Technology (FOS)" } }
      filter << { term: { "subjects.subject": "FOS: " + options[:field_of_science].humanize } }
    end
    filter << { term: { source: options[:source] } } if options[:source].present?
    filter << { range: { reference_count: { "gte": options[:has_references].to_i } } } if options[:has_references].present?
    filter << { range: { citation_count: { "gte": options[:has_citations].to_i } } } if options[:has_citations].present?
    filter << { range: { part_count: { "gte": options[:has_parts].to_i } } } if options[:has_parts].present?
    filter << { range: { part_of_count: { "gte": options[:has_part_of].to_i } } } if options[:has_part_of].present?
    filter << { range: { version_count: { "gte": options[:has_versions].to_i } } } if options[:has_versions].present?
    filter << { range: { version_of_count: { "gte": options[:has_version_of].to_i } } } if options[:has_version_of].present?
    filter << { range: { view_count: { "gte": options[:has_views].to_i } } } if options[:has_views].present?
    filter << { range: { download_count: { "gte": options[:has_downloads].to_i } } } if options[:has_downloads].present?
    filter << { term: { "landing_page.status": options[:link_check_status] } } if options[:link_check_status].present?
    filter << { exists: { field: "landing_page.checked" }} if options[:link_checked].present?
    filter << { term: { "landing_page.hasSchemaOrg": options[:link_check_has_schema_org] }} if options[:link_check_has_schema_org].present?
    filter << { term: { "landing_page.bodyHasPid": options[:link_check_body_has_pid] }} if options[:link_check_body_has_pid].present?
    filter << { exists: { field: "landing_page.schemaOrgId" }} if options[:link_check_found_schema_org_id].present?
    filter << { exists: { field: "landing_page.dcIdentifier" }} if options[:link_check_found_dc_identifier].present?
    filter << { exists: { field: "landing_page.citationDoi" }} if options[:link_check_found_citation_doi].present?
    filter << { range: { "landing_page.redirectCount": { "gte": options[:link_check_redirect_count_gte] } } } if options[:link_check_redirect_count_gte].present?
    filter << { terms: { aasm_state: options[:state].to_s.split(",") }} if options[:state].present?
    filter << { range: { registered: { gte: "#{options[:registered].split(",").min}||/y", lte: "#{options[:registered].split(",").max}||/y", format: "yyyy" }}} if options[:registered].present?
    filter << { term: { "creators.nameIdentifiers.nameIdentifier" => "https://orcid.org/#{orcid_from_url(options[:user_id])}" }} if options[:user_id].present?
    filter << { term: { "affiliation_id" => ror_from_url(options[:affiliation_id]) }} if options[:affiliation_id].present?
    filter << { term: { "funding_references.funderIdentifier" => "https://doi.org/#{doi_from_url(options[:funder_id])}" }} if options[:funder_id].present?
    filter << { term: { "creators.nameIdentifiers.nameIdentifierScheme" => "ORCID" }} if options[:has_person].present?
    filter << { term: { "creators.affiliation.affiliationIdentifierScheme" => "ROR" }} if options[:has_organization].present?
    filter << { term: { "funding_references.funderIdentifierType" => "Crossref Funder ID" }} if options[:has_funder].present?
    filter << { term: { consortium_id: options[:consortium_id] }} if options[:consortium_id].present?
    # TODO align PID parsing
    filter << { term: { "client.re3data_id" => doi_from_url(options[:re3data_id]) }} if options[:re3data_id].present?
    filter << { term: { "client.opendoar_id" => options[:opendoar_id] }} if options[:opendoar_id].present?
    filter << { terms: { "client.certificate" => options[:certificate].split(",") }} if options[:certificate].present?

    must_not << { terms: { provider_id: ["crossref", "medra", "op"] }} if options[:exclude_registration_agencies]

    # ES query can be optionally defined in different ways
    # So here we build it differently based upon options
    # This is mostly useful when trying to wrap it in a function_score query
    es_query = {}

    # The main bool query with filters
    bool_query = {
      must: must,
      must_not: must_not,
      filter: filter
    }

    # Function score is used to provide varying score to return different values
    # We use the bool query above as our principle query
    # Then apply additional function scoring as appropriate
    # Note this can be performance intensive.
    function_score = {
      query: {
        bool: bool_query
      },
      random_score: {
        "seed": Rails.env.test? ? "random_1234" : "random_#{rand(1...100000)}"
      }
    }

    if options[:random].present?
      es_query['function_score'] = function_score
      # Don't do any sorting for random results
      sort = nil
    else
      es_query['bool'] = bool_query
    end

    # Sample grouping is optional included aggregation
    if options[:sample_group].present?
      aggregations[:samples] = {
        terms: {
          field: options[:sample_group],
          size: 10000
        },
        aggs: {
          "samples_hits": {
            top_hits: {
              size: options[:sample_size].present? ? options[:sample_size] : 1
            }
          }
        }
      }
    end

    # three options for going through results are scroll, cursor and pagination
    # the default is pagination
    # scroll is triggered by the page[scroll] query parameter
    # cursor is triggered by the page[cursor] query parameter

    # can't use search wrapper function for scroll api
    # map function for scroll is small performance hit
    if options.dig(:page, :scroll).present?
      response = __elasticsearch__.client.search(
        index: self.index_name,
        scroll: options.dig(:page, :scroll),
        body: {
          size: options.dig(:page, :size),
          sort: sort,
          query: es_query,
          aggregations: aggregations,
          track_total_hits: true
        }.compact)
      Hashie::Mash.new({
        total: response.dig("hits", "total", "value"),
        results: response.dig("hits", "hits").map { |r| r["_source"] },
        scroll_id: response["_scroll_id"]
      })
    elsif options.dig(:page, :cursor).present?
      __elasticsearch__.search({
        size: options.dig(:page, :size),
        search_after: search_after,
        sort: sort,
        query: es_query,
        aggregations: aggregations,
        track_total_hits: true
      }.compact)
    else
      __elasticsearch__.search({
        size: options.dig(:page, :size),
        from: from,
        sort: sort,
        query: es_query,
        aggregations: aggregations,
        track_total_hits: true
      }.compact)
    end
  end

  def self.index_one(doi_id: nil)
    doi = Doi.where(doi: doi_id).first
    if doi.nil?
      Rails.logger.error "[MySQL] DOI " + doi_id + " not found."
      return nil
    end

    # doi.source_events.each { |event| IndexJob.perform_later(event) }
    # doi.target_events.each { |event| IndexJob.perform_later(event) }
    # sleep 1

    IndexJob.perform_later(doi)
  end

  def self.import_one(doi_id: nil)
    doi = Doi.where(doi: doi_id).first
    if doi.nil?
      Rails.logger.error "[MySQL] DOI #{doi_id} not found."
      return nil
    end

    string = doi.current_metadata.present? ? doi.clean_xml(doi.current_metadata.xml) : nil
    if string.blank?
      Rails.logger.error "[MySQL] No metadata for DOI #{doi.doi} found: " + doi.current_metadata.inspect
      return nil
    end

    meta = doi.read_datacite(string: string, sandbox: doi.sandbox)
    attrs = %w(creators contributors titles publisher publication_year types descriptions container sizes formats language dates identifiers related_identifiers funding_references geo_locations rights_list subjects content_url).map do |a|
      [a.to_sym, meta[a]]
    end.to_h.merge(schema_version: meta["schema_version"] || "http://datacite.org/schema/kernel-4", version_info: meta["version"], xml: string)

    # update_attributes will trigger validations and Elasticsearch indexing
    doi.update_attributes(attrs)
    Rails.logger.warn "[MySQL] Imported metadata for DOI " + doi.doi + "."
    doi
  rescue TypeError, NoMethodError, RuntimeError, ActiveRecord::StatementInvalid, ActiveRecord::LockWaitTimeout => e
    if doi.present?
      Rails.logger.error "[MySQL] Error importing metadata for " + doi.doi + ": " + e.message
      doi
    else
      Raven.capture_exception(e)
    end
  end

  def self.import_by_ids(options={})
    from_id = (options[:from_id] || Doi.minimum(:id)).to_i
    until_id = (options[:until_id] || Doi.maximum(:id)).to_i

    # get every id between from_id and end_id
    (from_id..until_id).step(500).each do |id|
      DoiImportByIdJob.perform_later(options.merge(id: id))
      Rails.logger.info "Queued importing for DOIs with IDs starting with #{id}." unless Rails.env.test?
    end

    (from_id..until_id).to_a.length
  end

  def self.import_by_client(client_id: nil)
    client = ::Client.where(symbol: client_id).first
    return nil if client.blank?

    index = if Rails.env.test?
      "dois-test"
    else
      self.active_index
    end
    errors = 0
    count = 0

    Doi.where(datacentre: client.id).find_in_batches(batch_size: 500) do |dois|
      response = Doi.__elasticsearch__.client.bulk \
        index:   index,
        type:    Doi.document_type,
        body:    dois.map { |doi| { index: { _id: doi.id, data: doi.as_indexed_json } } }

      # try to handle errors
      errors_in_response = response['items'].select { |k, v| k.values.first['error'].present? }
      errors += errors_in_response.length
      errors_in_response.each do |item|
        Rails.logger.error "[Elasticsearch] " + item.inspect
        doi_id = item.dig("index", "_id").to_i
        import_one(doi_id: doi_id) if doi_id > 0
      end

      count += dois.length
      Rails.logger.info "[Elasticsearch] Imported #{count} DOIs for client #{client_id}."
    end

    if errors > 1
      Rails.logger.error "[Elasticsearch] #{errors} errors importing #{count} DOIs for client #{client_id}."
    elsif count > 0
      Rails.logger.info "[Elasticsearch] Imported a total of #{count} DOIs for client #{client_id}."
    end

    count

  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => error
    Rails.logger.error "[Elasticsearch] Error #{error.message} importing DOIs for client #{client_id}."
  end

  def self.import_by_id(options={})
    return nil if options[:id].blank?

    id = options[:id].to_i
    index = if Rails.env.test?
              "dois-test"
            elsif options[:index].present?
              options[:index]
            else
              self.inactive_index
            end
    errors = 0
    count = 0

    Doi.where(id: id..(id + 499)).find_in_batches(batch_size: 500) do |dois|
      response = Doi.__elasticsearch__.client.bulk \
        index:   index,
        type:    Doi.document_type,
        body:    dois.map { |doi| { index: { _id: doi.id, data: doi.as_indexed_json } } }

      # try to handle errors
      errors_in_response = response['items'].select { |k, v| k.values.first['error'].present? }
      errors += errors_in_response.length
      errors_in_response.each do |item|
        Rails.logger.error "[Elasticsearch] " + item.inspect
        doi_id = item.dig("index", "_id").to_i
        import_one(doi_id: doi_id) if doi_id > 0
      end

      count += dois.length
    end

    if errors > 1
      Rails.logger.error "[Elasticsearch] #{errors} errors importing #{count} DOIs with IDs #{id} - #{(id + 499)}."
    elsif count > 0
      Rails.logger.info "[Elasticsearch] Imported #{count} DOIs with IDs #{id} - #{(id + 499)}."
    end

    count
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => error
    Rails.logger.info "[Elasticsearch] Error #{error.message} importing DOIs with IDs #{id} - #{(id + 499)}."

    count = 0

    Doi.where(id: id..(id + 499)).find_each do |doi|
      IndexJob.perform_later(doi)
      count += 1
    end

    Rails.logger.info "[Elasticsearch] Imported #{count} DOIs with IDs #{id} - #{(id + 499)}."

    count
  end

  def self.index_by_id(options={})
    return nil unless options[:id].present?

    id = options[:id].to_i
    index = if Rails.env.test?
              "dois-test"
            elsif options[:index].present?
              options[:index]
            else
              self.inactive_index
            end
    errors = 0
    count = 0

    Doi.where(id: id..(id + 499)).find_in_batches(batch_size: 500) do |dois|
      response = Doi.__elasticsearch__.client.bulk \
        index:   index,
        type:    Doi.document_type,
        body:    dois.map { |doi| { index: { _id: doi.id, data: doi.as_indexed_json } } }

      # log errors
      errors += response['items'].map { |k, v| k.values.first['error'] }.compact.length
      response['items'].select { |k, v| k.values.first['error'].present? }.each do |err|
        Rails.logger.error "[Elasticsearch] " + err.inspect
      end

      count += dois.length
    end

    if errors > 1
      Rails.logger.error "[Elasticsearch] #{errors} errors importing #{count} DOIs with IDs #{id} - #{(id + 499)}."
    elsif count > 0
      Rails.logger.info "[Elasticsearch] Imported #{count} DOIs with IDs #{id} - #{(id + 499)}."
    end

    count
  rescue Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge, Faraday::ConnectionFailed, ActiveRecord::LockWaitTimeout => error
    Rails.logger.info "[Elasticsearch] Error #{error.message} importing DOIs with IDs #{id} - #{(id + 499)}."

    count = 0

    Doi.where(id: id..(id + 499)).find_each do |doi|
      IndexJob.perform_later(doi)
      count += 1
    end

    Rails.logger.info "[Elasticsearch] Imported #{count} DOIs with IDs #{id} - #{(id + 499)}."

    count
  end

  def uid
    doi.downcase
  end

  def resource_type_id
    r = types.to_h["resourceTypeGeneral"]
    r.underscore.dasherize if RESOURCE_TYPES_GENERAL[r].present?
  rescue TypeError
    nil
  end

  def resource_type_id_and_name
    r = types.to_h["resourceTypeGeneral"]
    "#{r.underscore.dasherize}:#{RESOURCE_TYPES_GENERAL[r]}" if RESOURCE_TYPES_GENERAL[r].present?
  rescue TypeError
    nil
  end

  def media_ids
    media.pluck(:id).map { |m| Base32::URL.encode(m, split: 4, length: 16) }.compact
  end

  def view_count
    view_events.pluck(:total).inject(:+).to_i
  end

  def views_over_time
    view_events.pluck(:occurred_at, :total)
      .map { |v| { "yearMonth" => v[0].present? ? v[0].utc.iso8601[0..6] : nil, "total" => v[1] } }
      .sort_by { |h| h["yearMonth"] }
  end

  def download_count
    download_events.pluck(:total).inject(:+).to_i
  end

  def downloads_over_time
    download_events.pluck(:occurred_at, :total)
      .map { |v| { "yearMonth" => v[0].present? ? v[0].utc.iso8601[0..6] : nil, "total" => v[1] } }
      .sort_by { |h| h["yearMonth"] }
  end

  def reference_ids
    reference_events.pluck(:target_doi).compact.uniq.map(&:downcase)
  end

  def reference_count
    reference_events.pluck(:target_doi).uniq.length
  end

  def indexed_references
    Doi.query(nil, ids: reference_ids, page: { number: 1, size: 25 }).results
  end

  def citation_ids
    citation_events.pluck(:source_doi).compact.uniq.map(&:downcase)
  end

  # remove duplicate citing source dois
  def citation_count
    citation_events.pluck(:source_doi).uniq.length
  end

  # remove duplicate citing source dois,
  # then show distribution by year
  def citations_over_time
    citation_events.pluck(:occurred_at, :source_doi).uniq { |v| v[1] }
      .group_by { |v| v[0].utc.iso8601[0..3] }
      .map { |k, v| { "year" => k, "total" => v.length } }
      .sort_by { |h| h["year"] }
  end

  def indexed_citations
    Doi.query(nil, ids: citation_ids, page: { number: 1, size: 25 }).results
  end

  def part_ids
    part_events.pluck(:target_doi).compact.uniq.map(&:downcase)
  end

  def part_count
    part_events.pluck(:target_doi).uniq.length
  end

  def indexed_parts
    Doi.query(nil, ids: part_ids, page: { number: 1, size: 25 }).results.to_a
  end

  def part_of_ids
    part_of_events.pluck(:source_doi).compact.uniq.map(&:downcase)
  end

  def part_of_count
    part_of_events.pluck(:source_doi).uniq.length
  end

  def indexed_part_of
    Doi.query(nil, ids: part_of_ids, page: { number: 1, size: 25 }).results
  end

  def version_ids
    version_events.pluck(:target_doi).compact.uniq.map(&:downcase)
  end

  def version_count
    version_events.pluck(:target_doi).uniq.length
  end

  def indexed_versions
    Doi.query(nil, ids: version_ids, page: { number: 1, size: 25 }).results
  end

  def version_of_ids
    version_of_events.pluck(:source_doi).compact.uniq.map(&:downcase)
  end

  def version_of_count
    version_of_events.pluck(:source_doi).uniq.length
  end

  def indexed_version_of
    Doi.query(nil, ids: version_of_ids, page: { number: 1, size: 25 }).results
  end

  def xml_encoded
    Base64.strict_encode64(xml) if xml.present?
  rescue ArgumentError
    nil
  end

  # creator name in natural order: "John Smith" instead of "Smith, John"
  def creator_names
    Array.wrap(creators).map do |a|
      if a["familyName"].present?
        [a["givenName"], a["familyName"]].join(" ")
      elsif a["name"].to_s.include?(", ")
        a["name"].split(", ", 2).reverse.join(" ")
      else
        a["name"]
      end
    end
  end

  def self.convert_affiliations(options={})
    from_id = (options[:from_id] || Doi.minimum(:id)).to_i
    until_id = (options[:until_id] || Doi.maximum(:id)).to_i

    # get every id between from_id and end_id
    (from_id..until_id).step(500).each do |id|
      DoiConvertAffiliationByIdJob.perform_later(options.merge(id: id))
      Rails.logger.info "Queued converting affiliations for DOIs with IDs starting with #{id}." unless Rails.env.test?
    end

    (from_id..until_id).to_a.length
  end

  def self.convert_affiliation_by_id(options={})
    return nil if options[:id].blank?

    id = options[:id].to_i
    count = 0

    Doi.where(id: id..(id + 499)).find_each do |doi|
      should_update = false
      creators = Array.wrap(doi.creators).map do |c|
        if !(c.is_a?(Hash))
          Rails.logger.error "[MySQL] creators for DOI #{doi.doi} should be a hash."
        elsif c["affiliation"].nil?
          c["affiliation"] = []
          should_update = true
        elsif c["affiliation"].is_a?(String)
          c["affiliation"] = [{ "name" => c["affiliation"] }]
          should_update = true
        elsif c["affiliation"].is_a?(Hash)
          c["affiliation"] = Array.wrap(c["affiliation"])
          should_update = true
        elsif c["affiliation"].is_a?(Array)
          c["affiliation"] = c["affiliation"].map do |a|
            if a.nil?
              should_update = true

              a
            elsif a.is_a?(String)
              should_update = true

              { "name" => a }
            else
              a
            end
          end.compact
        end

        c
      end
      contributors = Array.wrap(doi.contributors).map do |c|
        if !(c.is_a?(Hash))
          Rails.logger.error "[MySQL] creators for DOI #{doi.doi} should be a hash."
        elsif c["affiliation"].nil?
          c["affiliation"] = []
          should_update = true
        elsif c["affiliation"].is_a?(String)
          c["affiliation"] = [{ "name" => c["affiliation"] }]
          should_update = true
        elsif c["affiliation"].is_a?(Hash)
          c["affiliation"] = Array.wrap(c["affiliation"])
          should_update = true
        elsif c["affiliation"].is_a?(Array)
          c["affiliation"] = c["affiliation"].map do |a|
            if a.nil?
              should_update = true

              a
            elsif a.is_a?(String)
              should_update = true

              { "name" => a }
            else
              a
            end
          end.compact
        end

        c
      end

      if should_update
        Doi.auditing_enabled = false
        doi.update_columns(creators: creators, contributors: contributors)
        Doi.auditing_enabled = true

        count += 1
      end

      unless (Array.wrap(doi.creators).all? { |c| c.is_a?(Hash) && c["affiliation"].is_a?(Array) && c["affiliation"].all? { |a| a.is_a?(Hash) } } && Array.wrap(doi.contributors).all? { |c| c.is_a?(Hash) && c["affiliation"].is_a?(Array) && c["affiliation"].all? { |a| a.is_a?(Hash) } })
        Rails.logger.error "[MySQL] Error converting affiliations for doi #{doi.doi}: creators #{doi.creators.inspect} contributors #{doi.contributors.inspect}."
        fail TypeError, "Affiliation for doi #{doi.doi} is of wrong type" if Rails.env.test?
      end
    end

    Rails.logger.info "[MySQL] Converted affiliations for #{count} DOIs with IDs #{id} - #{(id + 499)}." if count > 0

    count
  rescue TypeError, ActiveRecord::ActiveRecordError, ActiveRecord::LockWaitTimeout => error
    Rails.logger.error "[MySQL] Error converting affiliations for DOIs with IDs #{id} - #{(id + 499)}."
    count
  end

  def self.convert_containers(options={})
    from_id = (options[:from_id] || Doi.minimum(:id)).to_i
    until_id = (options[:until_id] || Doi.maximum(:id)).to_i

    # get every id between from_id and end_id
    (from_id..until_id).step(500).each do |id|
      DoiConvertContainerByIdJob.perform_later(options.merge(id: id))
      Rails.logger.info "Queued converting containers for DOIs with IDs starting with #{id}." unless Rails.env.test?
    end

    (from_id..until_id).to_a.length
  end

  def self.convert_container_by_id(options={})
    return nil if options[:id].blank?

    id = options[:id].to_i
    count = 0

    Doi.where(id: id..(id + 499)).find_each do |doi|
      should_update = false

      if doi.container.nil?
        should_update = true
        container = {}
      elsif !(doi.container.is_a?(Hash))
        Rails.logger.error "[MySQL] container for DOI #{doi.doi} should be a hash."
      elsif [doi.container["title"], doi.container["volume"], doi.container["issue"], doi.container["identifier"]].any? { |c| c.is_a?(Hash) }
        should_update = true
        container = {
          "type" => doi.container["type"],
          "identifier" => parse_attributes(doi.container["identifier"], first: true),
          "identifierType" => doi.container["identifierType"],
          "title" => parse_attributes(doi.container["title"]),
          "volume" => parse_attributes(doi.container["volume"]),
          "issue" => parse_attributes(doi.container["issue"]),
          "firstPage" => doi.container["firstPage"],
          "lastPage" => doi.container["lastPage"] }.compact
      end

      if should_update
        doi.update_columns(container: container)
        count += 1
      end
    end

    Rails.logger.info "[MySQL] Converted containers for #{count} DOIs with IDs #{id} - #{(id + 499)}." if count > 0

    count
  rescue TypeError, ActiveRecord::ActiveRecordError, ActiveRecord::LockWaitTimeout => error
    Rails.logger.error "[MySQL] Error converting containers for DOIs with IDs #{id} - #{(id + 499)}."
    count
  end

  def doi=(value)
    write_attribute(:doi, value.upcase) if value.present?
  end

  def formats=(value)
    write_attribute(:formats, Array.wrap(value))
  end

  def sizes=(value)
    write_attribute(:sizes, Array.wrap(value))
  end

  def dates=(value)
    write_attribute(:dates, Array.wrap(value))
  end

  def subjects=(value)
    write_attribute(:subjects, Array.wrap(value))
  end

  def rights_list=(value)
    write_attribute(:rights_list, Array.wrap(value))
  end

  def identifiers=(value)
    write_attribute(:identifiers, Array.wrap(value))
  end

  def related_identifiers=(value)
    write_attribute(:related_identifiers, Array.wrap(value))
  end

  def funding_references=(value)
    write_attribute(:funding_references, Array.wrap(value))
  end

  def geo_locations=(value)
    write_attribute(:geo_locations, Array.wrap(value))
  end

  def content_url=(value)
    write_attribute(:content_url, Array.wrap(value))
  end

  def container=(value)
    write_attribute(:container, value || {})
  end

  def types=(value)
    write_attribute(:types, value || {})
  end

  def landing_page=(value)
    write_attribute(:landing_page, value || {})
  end

  def identifier
    normalize_doi(doi, sandbox: !Rails.env.production?)
  end

  def client_id
    client.symbol.downcase if client.present?
  end

  def client_id_and_name
    "#{client_id}:#{client.name}" if client.present?
  end

  def client_id=(value)
    r = ::Client.where(symbol: value).first
    fail ActiveRecord::RecordNotFound unless r.present?

    write_attribute(:datacentre, r.id)
  end

  def provider_id
    client.provider.symbol.downcase if client.present?
  end

  def provider_id_and_name
    "#{provider_id}:#{client.provider.name}" if client.present?
  end

  def affiliation_id
    Array.wrap(creators).reduce([]) do |sum, creator|
      Array.wrap(creator.fetch("affiliation", nil)).each do |affiliation|
        sum << ror_from_url(affiliation.fetch("affiliationIdentifier", nil)) if affiliation.is_a?(Hash) && affiliation.fetch("affiliationIdentifierScheme", nil) == "ROR" && affiliation.fetch("affiliationIdentifier", nil).present?
      end

      sum
    end
  end

  def affiliation_id_and_name
    Array.wrap(creators).reduce([]) do |sum, creator|
      Array.wrap(creator.fetch("affiliation", nil)).each do |affiliation|
        sum << "#{ror_from_url(affiliation.fetch("affiliationIdentifier", nil)).to_s}:#{affiliation.fetch("name", nil).to_s}" if affiliation.is_a?(Hash) && affiliation.fetch("affiliationIdentifierScheme", nil) == "ROR" && affiliation.fetch("affiliationIdentifier", nil).present?
      end

      sum
    end
  end

  def prefix
    doi.split('/', 2).first if doi.present?
  end

  def suffix
    uid.split("/", 2).last if doi.present?
  end

  def registerable?
    true # && url.present?
  end

  # def is_valid?
  #   valid? && url.present?
  # end

  def is_registered_or_findable?
    %w(registered findable).include?(aasm_state) || %w(crossref medra op).include?(provider_id)
  end

  def validatable?
    %w(registered findable).include?(aasm_state) || should_validate || only_validate
  end

  # update URL in handle system for registered and findable state
  # providers europ, and DOI registration agencies do their own handle registration, so fetch url from handle system instead
  def update_url
    return nil if current_user.nil? || !is_registered_or_findable?

    if %w(europ).include?(provider_id) || %w(crossref.citations medra.citations jalc.citations kisti.citations op.citations).include?(client_id)
      UrlJob.perform_later(doi)
    else
      HandleJob.perform_later(doi)
    end
  end

  def update_media
    return nil if content_url.blank?

    media.delete_all

    Array.wrap(content_url).each_with_index do |c, index|
      media << Media.create(dataset: id, url: c, media_type: Array.wrap(formats)[index])
    end
  end

  # attributes to be sent to elasticsearch index
  def to_jsonapi
    attributes = {
      "doi" => doi,
      "state" => aasm_state,
      "created" => created,
      "updated" => date_updated }

    { "id" => doi, "type" => "dois", "attributes" => attributes }
  end

  def current_metadata
    metadata.order('metadata.created DESC').first
  end

  def metadata_version
    current_metadata ? current_metadata.metadata_version : 0
  end

  def current_media
    media.order('media.created DESC').first
  end

  def resource_type
    cached_resource_type_response(types["resourceTypeGeneral"].underscore.dasherize.downcase) if types.is_a?(Hash) && types["resourceTypeGeneral"].present?
  end

  def date_registered
    minted.iso8601 if minted.present?
  end

  def date_updated
    updated
  end

  def published
    get_date(dates, "issued") || publication_year.to_s
  end

  def cache_key
    timestamp = updated || Time.zone.now
    "dois/#{uid}-#{timestamp.iso8601}"
  end

  def event=(value)
    self.send(value) if %w(register publish hide show).include?(value)
  end

  def check_dates
    Array.wrap(dates).each do |d|
      errors.add(:dates, "Date #{d} should be an object instead of a string.") unless d.is_a?(Hash)
      #errors.add(:dates, "Date #{d["date"]} is not a valid date in ISO8601 format.") unless Date.edtf(d["date"]).present?
    end
  end

  def check_rights_list
    Array.wrap(rights_list).each do |r|
      errors.add(:rights_list, "Rights '#{r}' should be an object instead of a string.") unless r.is_a?(Hash)
    end
  end

  def check_titles
    Array.wrap(titles).each do |t|
      errors.add(:titles, "Title '#{t}' should be an object instead of a string.") unless t.is_a?(Hash)
    end
  end

  def check_descriptions
    Array.wrap(descriptions).each do |d|
      errors.add(:descriptions, "Description '#{d}' should be an object instead of a string.") unless d.is_a?(Hash)
    end
  end

  def check_subjects
    Array.wrap(subjects).each do |s|
      errors.add(:subjects, "Subject '#{s}' should be an object instead of a string.") unless s.is_a?(Hash)
    end
  end

  def check_creators
    Array.wrap(creators).each do |c|
      errors.add(:creators, "Creator '#{c}' should be an object instead of a string.") unless c.is_a?(Hash)
    end
  end

  def check_contributors
    Array.wrap(contributors).each do |c|
      errors.add(:contributors, "Contributor '#{c}' should be an object instead of a string.") unless c.is_a?(Hash)
    end
  end

  def check_identifiers
    Array.wrap(identifiers).each do |i|
      errors.add(:identifiers, "Identifier '#{i}' should be an object instead of a string.") unless i.is_a?(Hash)
    end
  end

  def check_related_identifiers
    Array.wrap(related_identifiers).each do |r|
      errors.add(:related_identifiers, "Related identifier '#{r}' should be an object instead of a string.") unless r.is_a?(Hash)
    end
  end

  def check_funding_references
    Array.wrap(funding_references).each do |f|
      errors.add(:funding_references, "Funding reference '#{f}' should be an object instead of a string.") unless f.is_a?(Hash)
    end
  end

  def check_geo_locations
    Array.wrap(geo_locations).each do |g|
      errors.add(:geo_locations, "Geolocation '#{g}' should be an object instead of a string.") unless g.is_a?(Hash)
    end
  end

  def check_landing_page
    errors.add(:landing_page, "Landing page '#{landing_page}' should be an object instead of a string.") unless landing_page.is_a?(Hash)
  end

  def check_types
    errors.add(:types, "Types '#{types}' should be an object instead of a string.") unless types.is_a?(Hash)
  end

  def check_container
    errors.add(:container, "Container '#{container}' should be an object instead of a string.") unless container.is_a?(Hash)
  end

  # to be used after DOIs were transferred to another DOI RA
  def self.delete_dois_by_prefix(prefix, options={})
    if prefix.blank?
      Rails.logger.error "[Error] No prefix provided."
      return nil
    end

    # query = options[:query] || "*"
    size = (options[:size] || 1000).to_i

    response = Doi.query(nil, prefix: prefix, page: { size: 1, cursor: [] })
    Rails.logger.info "#{response.results.total} DOIs found for prefix #{prefix}."

    if prefix && response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length > 0 do
        response = Doi.query(nil, prefix: prefix, page: { size: size, cursor: cursor })
        break unless response.results.results.length > 0

        Rails.logger.info "Deleting #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          DeleteJob.perform_later(d.doi)
        end
      end
    end

    response.results.total
  end

  # register DOIs in the handle system that have not been registered yet
  # provider europ registers their DOIs in the handle system themselves and are ignored
  def self.set_handle
    response = Doi.query("-registered:* +url:* -aasm_state:draft -provider_id:europ -agency:Crossref", page: { size: 1, cursor: [] })
    Rails.logger.info "#{response.results.total} DOIs found that are not registered in the Handle system."

    if response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length > 0 do
        response = Doi.query("-registered:* +url:* -aasm_state:draft -provider_id:europ -agency:Crossref", page: { size: 1000, cursor: cursor })
        break unless response.results.results.length > 0

        Rails.logger.info "[Handle] Register #{response.results.results.length} DOIs in the handle system starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          HandleJob.perform_later(d.doi)
        end
      end
    end
  end

  def self.set_url
    response = Doi.query("-url:* (+provider_id:ethz OR -aasm_status:draft)", page: { size: 1, cursor: [] })
    Rails.logger.info "#{response.results.total} DOIs with no URL found in the database."

    if response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length.postive? do
        response = Doi.query("-url:* (+provider_id:ethz OR -aasm_status:draft)", page: { size: 1000, cursor: cursor })
        break unless response.results.results.length.positive?

        Rails.logger.info "[Handle] Update URL for #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          UrlJob.perform_later(d.doi)
        end
      end
    end
  end

  def self.set_minted
    response = Doi.query("provider_id:ethz AND +aasm_state:draft +url:*", page: { size: 1, cursor: [] })
    Rails.logger.info "#{response.results.total} draft DOIs from provider ETHZ found in the database."

    if response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length.positive? do
        response = Doi.query("provider_id:ethz AND +aasm_state:draft +url:*", page: { size: 1000, cursor: cursor })
        break unless response.results.results.length.positive?

        Rails.logger.info "[MySQL] Set minted for #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          UrlJob.perform_later(d.doi)
        end
      end
    end
  end

  def self.transfer(options={})
    if options[:client_id].blank?
      Rails.logger.error "[Transfer] No client provided."
      return nil
    end

    if options[:client_target_id].blank?
      Rails.logger.error "[Transfer] No target client provided."
      return nil
    end

    query = options[:query] || "*"
    size = (options[:size] || 1000).to_i

    response = Doi.query(nil, client_id: options[:client_id].downcase, page: { size: 1, cursor: [] })
    Rails.logger.info "[Transfer] #{response.results.total} DOIs found for client #{options[:client_id]}."

    if options[:client_id] && options[:client_target_id] && response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length.positive? do
        response = Doi.query(nil, client_id: options[:client_id].downcase, page: { size: size, cursor: cursor })
        break unless response.results.results.length.positive?

        Rails.logger.info "[Transfer] Transferring #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]
        Rails.logger.info "[Transfer] Next cursor for transfer is #{cursor.inspect}."
        response.results.results.each do |d|
          TransferJob.perform_later(d.doi, client_target_id: options[:client_target_id])
        end
      end
    end

    response.results.total
  end

  # Transverses the index in batches and using the cursor pagination and executes a Job that matches the query and filer
  # Options:
  # +filter+:: paramaters to filter the index
  # +label+:: String to output in the logs printout
  # +query+:: ES query to filter the index
  # +job_name+:: Acive Job class name of the Job that would be executed on every matched results
  def self.loop_through_dois(options)
    size = (options[:size] || 1000).to_i
    cursor = [options[:from_id] || Doi.minimum(:id).to_i, options[:until_id] || Doi.maximum(:id).to_i]
    filter = options[:filter] || {}
    label = options[:label] || ""
    job_name = options[:job_name] || ""
    query = options[:query] || nil


    response = Doi.query(query, filter.merge(page: { size: 1, cursor: [] }))
    Rails.logger.info "#{label} #{response.results.total} Dois with #{label}."

    # walk through results using cursor
    if response.results.total.positive?
      while response.results.results.length.positive?
        response = Doi.query(query, filter.merge(page: { size: size, cursor: cursor }))
        break unless response.results.results.length.positive?

        Rails.logger.info "#{label} #{response.results.results.length}  Dois starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]
        Rails.logger.info "#{label} Cursor: #{cursor} "

        ids = response.results.results.map(&:uid)
        ids.each do |id|
          Object.const_get(job_name).perform_later(id, options)
        end
      end
    end
  end


  # save to metadata table when xml has changed
  def save_metadata
    metadata.build(doi: self, xml: xml, namespace: schema_version) if xml.present? && xml_changed?
  end

  def set_defaults
    self.is_active = (aasm_state == "findable") ? "\x01" : "\x00"
    self.version = version.present? ? version + 1 : 1
    self.updated = Time.zone.now.utc.iso8601
  end

  def self.repair_landing_page(doi_id)
    if doi_id.blank?
      Rails.logger.error "[Error] No DOI provided."
      return nil
    end

    doi = Doi.where(doi: doi_id).first
    if doi.nil?
      Rails.logger.error "[Error] DOI " + doi_id + " not found."
      return nil
    end

    begin
      landing_page = doi.landing_page

      # Schema.org ID's can be an array, they must always be a single keyword, so extract where possible.
      schema_org_id = landing_page['schemaOrgId']

      if schema_org_id.kind_of?(Array)
        # There shouldn't be anymore than a singular entry, but even if there are more, it's not something we can handle here
        # Instead just try and grab the first value of the first entry.
        landing_page['schemaOrgId'] = schema_org_id[0]["value"]
      end

      # Update with changes
      doi.update_columns("landing_page": landing_page)

      Rails.logger.info "Updated landing page data for DOI: " + doi.doi

    rescue TypeError, NoMethodError => error
      Rails.logger.error "Error updating landing page data: " + doi.doi + " - " + error.message
    end
  end

  def self.migrate_landing_page(options={})
    Rails.logger.info "Starting migration"

    # Handle camel casing first.
    Doi.where.not('last_landing_page_status_result' => nil).find_each do |doi|
      begin
        # First we try and fix into camel casing
        result = doi.last_landing_page_status_result
        mappings = {
          "body-has-pid" => "bodyHasPid",
          "dc-identifier" => "dcIdentifier",
          "citation-doi" => "citationDoi",
          "redirect-urls" => "redirectUrls",
          "schema-org-id" => "schemaOrgId",
          "has-schema-org" => "hasSchemaOrg",
          "redirect-count" => "redirectCount",
          "download-latency" => "downloadLatency",
        }
        result = result.map {|k, v| [mappings[k] || k, v] }.to_h
        # doi.update_columns("last_landing_page_status_result": result)

        # Do a fix of the stored download Latency
        # Sometimes was floating point precision, we dont need this
        download_latency = result['downloadLatency']
        download_latency = download_latency.nil? ? download_latency : download_latency.round

        # Try to put the checked date into ISO8601
        # If we dont have one (there was legacy reasons) then set to unix epoch
        checked = doi.last_landing_page_status_check
        checked = checked.nil? ? Time.at(0) : checked
        checked = checked.iso8601

        # Next we want to build a new landing_page result.
        landing_page = {
          "checked" => checked,
          "status" => doi.last_landing_page_status,
          "url" => doi.last_landing_page,
          "contentType" => doi.last_landing_page_content_type,
          "error" => result['error'],
          "redirectCount" => result['redirectCount'],
          "redirectUrls" => result['redirectUrls'],
          "downloadLatency" => download_latency,
          "hasSchemaOrg" => result['hasSchemaOrg'],
          "schemaOrgId" => result['schemaOrgId'],
          "dcIdentifier" => result['dcIdentifier'],
          "citationDoi" => result['citationDoi'],
          "bodyHasPid" => result['bodyHasPid'],
        }

        doi.update_columns("landing_page": landing_page)

        Rails.logger.info "Updated " + doi.doi

      rescue TypeError, NoMethodError => error
        Rails.logger.error "Error updating landing page " + doi.doi + ": " + error.message
      end
    end
  end
end
