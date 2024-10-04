# frozen_string_literal: true

require "maremma"
require "benchmark"

class Doi < ApplicationRecord
  self.ignored_columns += [:publisher]
  PUBLISHER_JSON_SCHEMA = "#{Rails.root}/app/models/schemas/doi/publisher.json"
  audited only: %i[doi url creators contributors titles publisher_obj publication_year types descriptions container sizes formats version_info language dates identifiers related_identifiers related_items funding_references geo_locations rights_list subjects schema_version content_url landing_page aasm_state source reason]

  # disable STI
  self.inheritance_column = :_type_disabled

  include Metadatable
  include Cacheable
  include Dateable

  # include helper module for generating random DOI suffixes
  include Helpable

  include Modelable

  # include helper module for converting and exposing metadata
  include Crosscitable

  # include state machine
  include AASM

  # include helper module for Elasticsearch
  include Indexable

  # include helper module for sending emails
  include Mailable

  include Elasticsearch::Model

  aasm whiny_transitions: false do
    # draft is initial state for new DOIs.
    state :draft, initial: true
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
      transitions from: %i[registered findable], to: :flagged
    end

    event :link_check do
      transitions from: %i[tombstoned registered findable flagged], to: :broken
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
  attribute :publisher, :string, default: nil

  belongs_to :client, foreign_key: :datacentre, optional: true
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

  validates_presence_of :doi
  validates_presence_of :url, if: Proc.new { |doi| doi.is_registered_or_findable? }

  json_schema_validation = {
    message: ->(errors) { errors },
    schema: PUBLISHER_JSON_SCHEMA
  }

  def validate_publisher_obj?(doi)
    doi.validatable? && doi.publisher_obj? && !(doi.publisher_obj.blank? || doi.publisher_obj.all?(nil))
  end

  validates :publisher_obj, if: ->(doi) { validate_publisher_obj?(doi) }, json: json_schema_validation

  # from https://www.crossref.org/blog/dois-and-matching-regular-expressions/ but using uppercase
  validates_format_of :doi, with: /\A10\.\d{4,5}\/[-._;()\/:a-zA-Z0-9*~$=]+\z/, on: :create
  validates_format_of :url, with: /\A(ftp|http|https):\/\/\S+/, if: :url?, message: "URL is not valid"
  validates_uniqueness_of :doi, message: "This DOI has already been taken", unless: :only_validate
  validates_inclusion_of :agency, in: %w(datacite crossref kisti medra istic jalc airiti cnki op), allow_blank: true
  validates :last_landing_page_status, numericality: { only_integer: true }, if: :last_landing_page_status?
  validates :xml, presence: true, xml_schema: true, if: Proc.new { |doi| doi.validatable? }
  validate :check_url, if: Proc.new { |doi| doi.is_registered_or_findable? }
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
  validate :check_related_items, if: :related_items?
  validate :check_funding_references, if: :funding_references?
  validate :check_geo_locations, if: :geo_locations?
  validate :check_language, if: :language?

  after_commit :update_url, on: %i[create update]
  after_commit :update_media, on: %i[create update]

  before_validation :update_publisher, if: [ :will_save_change_to_publisher?, :publisher? ]
  before_validation :update_xml, if: :regenerate
  before_validation :update_agency
  before_validation :update_field_of_science
  before_validation :update_language, if: :language?
  before_validation :update_rights_list, if: :rights_list?
  before_validation :update_identifiers
  before_validation :update_types
  before_save :set_defaults, :save_metadata
  before_create { self.created = Time.zone.now.utc.iso8601 }

  FIELD_OF_SCIENCE_SCHEME = "Fields of Science and Technology (FOS)"

  scope :q, ->(query) { where("dataset.doi = ?", query) }

  # use different index for testing
  if Rails.env.test?
    index_name "dois-test#{ENV['TEST_ENV_NUMBER']}"
  elsif ENV["ES_PREFIX"].present?
    index_name "dois-#{ENV['ES_PREFIX']}"
  else
    index_name "dois"
  end

  settings index: {
    analysis: {
      analyzer: {
        string_lowercase: { tokenizer: "keyword", filter: %w(lowercase ascii_folding) },
      },
      normalizer: {
        keyword_lowercase: { type: "custom", filter: %w(lowercase) },
      },
      filter: {
        ascii_folding: { type: "asciifolding", preserve_original: true },
      },
    },
  } do
    mapping dynamic: "false" do
      indexes :id,                             type: :keyword
      indexes :uid,                            type: :keyword, normalizer: "keyword_lowercase"
      indexes :doi,                            type: :keyword
      indexes :identifier,                     type: :keyword
      indexes :url,                            type: :text, fields: { keyword: { type: "keyword" } }
      indexes :creators,                       type: :object, properties: {
        nameType: { type: :keyword },
        nameIdentifiers: { type: :object, properties: {
          nameIdentifier: { type: :keyword },
          nameIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        } },
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text },
        affiliation: { type: :object, properties: {
          name: { type: :keyword },
          affiliationIdentifier: { type: :keyword },
          affiliationIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        } },
      }
      indexes :contributors, type: :object, properties: {
        nameType: { type: :keyword },
        nameIdentifiers: { type: :object, properties: {
          nameIdentifier: { type: :keyword },
          nameIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        } },
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text },
        affiliation: { type: :object, properties: {
          name: { type: :keyword },
          affiliationIdentifier: { type: :keyword },
          affiliationIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        } },
        contributorType: { type: :keyword },
      }
      indexes :creators_and_contributors, type: :object, properties: {
        nameType: { type: :keyword },
        nameIdentifiers: { type: :object, properties: {
          nameIdentifier: { type: :keyword },
          nameIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        } },
        name: { type: :text },
        givenName: { type: :text },
        familyName: { type: :text },
        affiliation: { type: :object, properties: {
          name: { type: :keyword },
          affiliationIdentifier: { type: :keyword },
          affiliationIdentifierScheme: { type: :keyword },
          schemeUri: { type: :keyword },
        } },
        contributorType: { type: :keyword },
      }
      indexes :creator_names,                  type: :text
      indexes :titles,                         type: :object, properties: {
        title: { type: :text, fields: { keyword: { type: "keyword" } } },
        titleType: { type: :keyword },
        lang: { type: :keyword },
      }
      indexes :descriptions, type: :object, properties: {
        description: { type: :text },
        descriptionType: { type: :keyword },
        lang: { type: :keyword },
      }
      indexes :publisher,                      type: :text,
        fields: { keyword: { type: "keyword" } }
      indexes :publication_year,               type: :date, format: "yyyy", ignore_malformed: true
      indexes :client_id,                      type: :keyword
      indexes :provider_id,                    type: :keyword
      indexes :consortium_id,                  type: :keyword
      indexes :resource_type_id,               type: :keyword
      indexes :person_id,                      type: :keyword
      indexes :affiliation_id,                 type: :keyword
      indexes :fair_affiliation_id,            type: :keyword
      indexes :organization_id,                type: :keyword
      indexes :fair_organization_id,           type: :keyword
      indexes :related_dmp_organization_id,    type: :keyword
      indexes :client_id_and_name,             type: :keyword
      indexes :provider_id_and_name,           type: :keyword
      indexes :resource_type_id_and_name,      type: :keyword
      indexes :affiliation_id_and_name,        type: :keyword
      indexes :fair_affiliation_id_and_name,   type: :keyword
      indexes :media_ids,                      type: :keyword
      indexes :media,                          type: :object, properties: {
        type: { type: :keyword },
        id: { type: :keyword },
        uid: { type: :keyword },
        url: { type: :text },
        media_type: { type: :keyword },
        version: { type: :keyword },
        created: { type: :date, ignore_malformed: true },
        updated: { type: :date, ignore_malformed: true },
      }
      indexes :identifiers, type: :object, properties: {
        identifierType: { type: :keyword },
        identifier: { type: :keyword, normalizer: "keyword_lowercase" },
      }
      indexes :related_identifiers, type: :object, properties: {
        relatedIdentifierType: { type: :keyword },
        relatedIdentifier: { type: :keyword, normalizer: "keyword_lowercase" },
        relationType: { type: :keyword },
        relatedMetadataScheme: { type: :keyword },
        schemeUri: { type: :keyword },
        schemeType: { type: :keyword },
        resourceTypeGeneral: { type: :keyword },
      }
      indexes :related_items,                       type: :object, properties: {
        relatedItemType: { type: :keyword },
        relationType: { type: :keyword },
        relatedItemIdentifier: { type: :object, properties: {
          relatedItemIdentifier: { type: :keyword, normalizer: "keyword_lowercase" },
          relatedItemIdentifierType: { type: :keyword },
          relatedMetadataScheme: { type: :keyword },
          schemeURI: { type: :keyword },
          schemeType: { type: :keyword },
        } },
        creators: { type: :object, properties: {
          nameType: { type: :text },
          name: { type: :text },
          givenName: { type: :text },
          familyName: { type: :text },
        } },
        titles: { type: :object, properties: {
          title: { type: :text, fields: { keyword: { type: "keyword" } } },
          titleType: { type: :keyword },
        } },
        volume: { type: :keyword },
        issue: { type: :keyword },
        number: { type: :keyword },
        numberType: { type: :keyword },
        firstPage: { type: :keyword },
        lastPage: { type: :keyword },
        publisher: { type: :keyword },
        publicationYear: { type: :keyword },
        edition: { type: :keyword },
        contributors: { type: :object, properties: {
          contributorType: { type: :text },
          name: { type: :text },
          nameType: { type: :text },
          givenName: { type: :text },
          familyName: { type: :text },
        } },
      }
      indexes :types, type: :object, properties: {
        resourceTypeGeneral: { type: :keyword },
        resourceType: { type: :keyword },
        schemaOrg: { type: :keyword },
        bibtex: { type: :keyword },
        citeproc: { type: :keyword },
        ris: { type: :keyword },
      }
      indexes :funding_references, type: :object, properties: {
        funderName: { type: :keyword },
        funderIdentifier: { type: :keyword, normalizer: "keyword_lowercase" },
        funderIdentifierType: { type: :keyword },
        schemeUri: { type: :keyword },
        awardNumber: { type: :keyword },
        awardUri: { type: :keyword },
        awardTitle: { type: :keyword },
      }
      indexes :dates, type: :object, properties: {
        date: { type: :text },
        dateType: { type: :keyword },
        dateInformation: { type: :keyword },
      }
      indexes :geo_locations, type: :object, properties: {
        geoLocationPoint: { type: :object },
        geoLocationBox: { type: :object },
        geoLocationPlace: { type: :keyword },
      }
      indexes :rights_list, type: :object, properties: {
        rights: { type: :keyword },
        rightsUri: { type: :keyword },
        rightsIdentifier: { type: :keyword, normalizer: "keyword_lowercase" },
        rightsIdentifierScheme: { type: :keyword },
        schemeUri: { type: :keyword },
        lang: { type: :keyword },
      }
      indexes :subjects, type: :object, properties: {
        subjectScheme: { type: :keyword },
        subject: { type: :keyword },
        schemeUri: { type: :keyword },
        valueUri: { type: :keyword },
        lang: { type: :keyword },
        classificationCode: { type: :keyword },
      }
      indexes :container, type: :object, properties: {
        type: { type: :keyword },
        identifier: { type: :keyword, normalizer: "keyword_lowercase" },
        identifierType: { type: :keyword },
        title: { type: :keyword },
        volume: { type: :keyword },
        issue: { type: :keyword },
        firstPage: { type: :keyword },
        lastPage: { type: :keyword },
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
        url: { type: :text, fields: { keyword: { type: "keyword" } } },
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
        bodyHasPid: { type: :boolean },
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
        name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true } } },
        alternate_name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true } } },
        description: { type: :text },
        language: { type: :keyword },
        client_type: { type: :keyword },
        repository_type: { type: :keyword },
        certificate: { type: :keyword },
        system_email: { type: :text, fields: { keyword: { type: "keyword" } } },
        version: { type: :integer },
        is_active: { type: :keyword },
        domains: { type: :text },
        year: { type: :integer },
        url: { type: :text, fields: { keyword: { type: "keyword" } } },
        software: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true } } },
        cache_key: { type: :keyword },
        created: { type: :date },
        updated: { type: :date },
        deleted_at: { type: :date },
        cumulative_years: { type: :integer, index: "false" },
        subjects: { type: :object, properties: {
          subjectScheme: { type: :keyword },
          subject: { type: :keyword },
          schemeUri: { type: :keyword },
          valueUri: { type: :keyword },
          lang: { type: :keyword },
          classificationCode: { type: :keyword },
        } }
      }
      indexes :provider, type: :object, properties: {
        id: { type: :keyword },
        uid: { type: :keyword, normalizer: "keyword_lowercase" },
        symbol: { type: :keyword },
        client_ids: { type: :keyword },
        prefix_ids: { type: :keyword },
        name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true } } },
        display_name: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true } } },
        system_email: { type: :text, fields: { keyword: { type: "keyword" } } },
        group_email: { type: :text, fields: { keyword: { type: "keyword" } } },
        version: { type: :integer },
        is_active: { type: :keyword },
        year: { type: :integer },
        description: { type: :text },
        website: { type: :text, fields: { keyword: { type: "keyword" } } },
        logo_url: { type: :text },
        region: { type: :keyword },
        focus_area: { type: :keyword },
        organization_type: { type: :keyword },
        member_type: { type: :keyword },
        consortium_id: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", "analyzer": "string_lowercase", "fielddata": true } } },
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
          state: { type: :text },
          organization: { type: :text },
          department: { type: :text },
          city: { type: :text },
          country: { type: :text },
          address: { type: :text },
        } },
        technical_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        secondary_technical_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
          family_name: { type: :text },
        } },
        billing_contact: { type: :object, properties: {
          email: { type: :text },
          given_name: { type: :text },
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
      indexes :primary_title, type: :object, properties: {
        title: { type: :text, fields: { keyword: { type: "keyword" }, raw: { type: "text", analyzer: "string_lowercase", "fielddata": true } } },
        titleType: { type: :keyword },
        lang: { type: :keyword },
      }
      indexes :fields_of_science, type: :keyword
      indexes :fields_of_science_combined, type: :keyword
      indexes :fields_of_science_repository, type: :keyword
      indexes :related_doi, type: :object, properties: {
        client_id: { type: :keyword },
        doi: { type: :keyword },
        organization_id: { type: :keyword },
        person_id: { type: :keyword },
        resource_type_id: { type: :keyword },
        resource_type_id_and_name: { type: :keyword },
      }
      indexes :publisher_obj, type: :object, properties: {
        name: { type: :text, fields: { keyword: { type: "keyword" } } },
        publisherIdentifier: { type: :keyword, normalizer: "keyword_lowercase" },
        publisherIdentifierScheme: { type: :keyword },
        schemeUri: { type: :keyword },
        lang: { type: :keyword },
      }
    end
  end

  def as_indexed_json(_options = {})
    {
      "id" => uid,
      "uid" => uid,
      "doi" => doi,
      "identifier" => identifier,
      "url" => url,
      "creators" => Array.wrap(creators),
      "contributors" => Array.wrap(contributors),
      "creators_and_contributors" => Array.wrap(creators) + Array.wrap(contributors),
      "creator_names" => creator_names,
      "titles" => Array.wrap(titles),
      "descriptions" => Array.wrap(descriptions),
      "publisher" => publisher && publisher["name"],
      "client_id" => client_id,
      "provider_id" => provider_id,
      "consortium_id" => consortium_id,
      "resource_type_id" => resource_type_id,
      "person_id" => person_id,
      "client_id_and_name" => client_id_and_name,
      "provider_id_and_name" => provider_id_and_name,
      "resource_type_id_and_name" => resource_type_id_and_name,
      "affiliation_id" => affiliation_id,
      "fair_affiliation_id" => fair_affiliation_id,
      "organization_id" => organization_id,
      "fair_organization_id" => fair_organization_id,
      "related_dmp_organization_id" => related_dmp_organization_and_affiliation_id,
      "affiliation_id_and_name" => affiliation_id_and_name,
      "fair_affiliation_id_and_name" => fair_affiliation_id_and_name,
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
      "related_items" => Array.wrap(related_items),
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
      "fields_of_science" => fields_of_science,
      "fields_of_science_repository" => fields_of_science_repository,
      "fields_of_science_combined" => fields_of_science_combined,
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
      "registered" => registered.try(:iso8601),
      "created" => created.try(:iso8601),
      "updated" => updated.try(:iso8601),
      "published" => published.try(:iso8601),
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
      "primary_title" => Array.wrap(primary_title),
      "publisher_obj" => publisher,
    }
  end


  def self.query_aggregations(disable_facets: false)
    if !disable_facets
      {
        # number of resourceTypeGeneral increased from 16 to 28 in schema 4.4
        resource_types: { terms: { field: "resource_type_id_and_name", size: 30, min_doc_count: 1 } },
        states: { terms: { field: "aasm_state", size: 3, min_doc_count: 1 } },
        published: {
          date_histogram: {
            field: "publication_year",
            interval: "year",
            format: "year",
            order: {
              _key: "desc",
            },
            min_doc_count: 1,
          },
        },
        registration_agencies: { terms: { field: "agency", size: 10, min_doc_count: 1 } },
        created: { date_histogram: { field: "created", interval: "year", format: "year", order: { _key: "desc" }, min_doc_count: 1 },
                  aggs: { bucket_truncate: { bucket_sort: { size: 10 } } } },
        registered: { date_histogram: { field: "registered", interval: "year", format: "year", order: { _key: "desc" }, min_doc_count: 1 },
                      aggs: { bucket_truncate: { bucket_sort: { size: 10 } } } },
        providers: { terms: { field: "provider_id_and_name", size: 10, min_doc_count: 1 } },
        clients: { terms: { field: "client_id_and_name", size: 10, min_doc_count: 1 } },
        affiliations: { terms: { field: "affiliation_id_and_name", size: 10, min_doc_count: 1 } },
        prefixes: { terms: { field: "prefix", size: 10, min_doc_count: 1 } },
        schema_versions: { terms: { field: "schema_version", size: 10, min_doc_count: 1 } },
        link_checks_status: { terms: { field: "landing_page.status", size: 10, min_doc_count: 1 } },
        # link_checks_has_schema_org: { terms: { field: 'landing_page.hasSchemaOrg', size: 2, min_doc_count: 1 } },
        # link_checks_schema_org_id: { value_count: { field: "landing_page.schemaOrgId" } },
        # link_checks_dc_identifier: { value_count: { field: "landing_page.dcIdentifier" } },
        # link_checks_citation_doi: { value_count: { field: "landing_page.citationDoi" } },
        # links_checked: { value_count: { field: "landing_page.checked" } },
        # sources: { terms: { field: 'source', size: 15, min_doc_count: 1 } },
        subjects: { terms: { field: "subjects.subject", size: 10, min_doc_count: 1 } },
        pid_entities: {
          filter: { term: { "subjects.subjectScheme": "PidEntity" } },
          aggs: {
            subject: { terms: { field: "subjects.subject", size: 10, min_doc_count: 1,
                                include: %w(Dataset Publication Software Organization Funder Person Grant Sample Instrument Repository Project) } },
          },
        },
        fields_of_science: {
          filter: { term: { "subjects.subjectScheme": "Fields of Science and Technology (FOS)" } },
          aggs: {
            subject: { terms: { field: "subjects.subject", size: 10, min_doc_count: 1,
                                include: "FOS:.*" } },
          },
        },
        licenses: { terms: { field: "rights_list.rightsIdentifier", size: 10, min_doc_count: 1 } },
        languages: { terms: { field: "language", size: 10, min_doc_count: 1 } },
        certificates: { terms: { field: "client.certificate", size: 10, min_doc_count: 1 } },
        views: {
          date_histogram: { field: "publication_year", interval: "year", format: "year", order: { _key: "desc" }, min_doc_count: 1 },
          aggs: {
            metric_count: { sum: { field: "view_count" } },
            bucket_truncate: { bucket_sort: { size: 10 } },
          },
        },
        downloads: {
          date_histogram: { field: "publication_year", interval: "year", format: "year", order: { _key: "desc" }, min_doc_count: 1 },
          aggs: {
            metric_count: { sum: { field: "download_count" } },
            bucket_truncate: { bucket_sort: { size: 10 } },
          },
        },
        citations: {
          date_histogram: { field: "publication_year", interval: "year", format: "year", order: { _key: "desc" }, min_doc_count: 1 },
          aggs: {
            metric_count: { sum: { field: "citation_count" } },
            bucket_truncate: { bucket_sort: { size: 10 } },
          },
        },
      }
    end
  end

  def self.provider_aggregations
    { providers_totals: { terms: { field: "provider_id", size: ::Provider.__elasticsearch__.count, min_doc_count: 1 }, aggs: sub_aggregations } }
  end

  def self.client_aggregations
    { clients_totals: { terms: { field: "client_id", size: ::Client.__elasticsearch__.count, min_doc_count: 1 }, aggs: sub_aggregations } }
  end

  def self.client_export_aggregations
    { clients_totals: { terms: { field: "client_id", size: ::Client.__elasticsearch__.count, min_doc_count: 1 }, aggs: export_sub_aggregations } }
  end

  def self.prefix_aggregations
    { prefixes_totals: { terms: { field: "prefix", size: ::Prefix.count, min_doc_count: 1 }, aggs: sub_aggregations } }
  end

  def self.sub_aggregations
    {
      states: { terms: { field: "aasm_state", size: 4, min_doc_count: 1 } },
      this_month: { date_range: { field: "created", ranges: { from: "now/M", to: "now/d" } } },
      this_year: { date_range: { field: "created", ranges: { from: "now/y", to: "now/d" } } },
      last_year: { date_range: { field: "created", ranges: { from: "now-1y/y", to: "now/y-1d" } } },
      two_years_ago: { date_range: { field: "created", ranges: { from: "now-2y/y", to: "now-1y/y-1d" } } },
    }
  end

  def self.export_sub_aggregations
    {
      this_year: { date_range: { field: "created", ranges: { from: "now/y", to: "now/d" } } },
      last_year: { date_range: { field: "created", ranges: { from: "now-1y/y", to: "now/y-1d" } } },
      two_years_ago: { date_range: { field: "created", ranges: { from: "now-2y/y", to: "now-1y/y-1d" } } },
    }
  end

  def self.igsn_id_catalog_aggregations
    {
      created_by_month: { date_histogram: { field: "created", interval: "month", format: "yyyy-MM", order: { _key: "desc" }, min_doc_count: 1 },
      aggs: { bucket_truncate: { bucket_sort: { size: 10 } } } }
    }
  end

  def self.query_fields
    ["uid^50", "related_identifiers.relatedIdentifier^3", "titles.title^3", "creator_names^3", "creators.id^3", "publisher^3", "descriptions.description^3", "subjects.subject^3"]
  end

  # return results for one or more ids
  def self.find_by_ids(ids, options = {})
    ids = ids.split(",") if ids.is_a?(String)

    options[:page] ||= {}
    options[:page][:number] ||= 1
    options[:page][:size] ||= 1000
    options[:sort] ||= { created: { order: "asc" } }

    must = [{ terms: { doi: ids.map(&:upcase) } }]
    must << { terms: { aasm_state: options[:state].to_s.split(",") } } if options[:state].present?
    must << { terms: { provider_id: options[:provider_id].split(",") } } if options[:provider_id].present?
    must << { terms: { client_id: options[:client_id].to_s.split(",") } } if options[:client_id].present?

    __elasticsearch__.search(
      from: (options.dig(:page, :number) - 1) * options.dig(:page, :size),
      size: options.dig(:page, :size),
      sort: [options[:sort]],
      query: {
        bool: {
          must: must,
        },
      },
      aggregations: query_aggregations(disable_facets: options[:disable_facets]),
    )
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

  def self.stats_query(options = {})
    filter = []
    filter << { term: { provider_id: { value: options[:provider_id], case_insensitive: true } } } if options[:provider_id].present?
    filter << { term: { client_id: { value: options[:client_id], case_insensitive: true } } } if options[:client_id].present?
    filter << { term: { consortium_id: { value: options[:consortium_id], case_insensitive: true } } } if options[:consortium_id].present?
    filter << { term: { "creators.nameIdentifiers.nameIdentifier" => "https://orcid.org/#{orcid_from_url(options[:user_id])}" } } if options[:user_id].present?

    aggregations = {
      created: { date_histogram: { field: "created", interval: "year", format: "year", order: { _key: "desc" }, min_doc_count: 1 },
                 aggs: { bucket_truncate: { bucket_sort: { size: 12 } } } },
    }

    __elasticsearch__.search(
      query: {
        bool: {
          must: [{ match_all: {} }],
          filter: filter,
        },
      },
      aggregations: aggregations,
    )
  end

  # query for graphql, removing options that are not needed
  def self.gql_query(query, options = {})
    builder = Doi::GraphqlQuery::Builder.new(query, options)
    __elasticsearch__.search(
      builder.build_full_search_query
    )
  end

  def self.query(query, options = {})
    # support scroll api
    # map function is small performance hit
    if options[:scroll_id].present? && options.dig(:page, :scroll)
      begin
        response = __elasticsearch__.client.scroll(body:
          { scroll_id: options[:scroll_id],
            scroll: options.dig(:page, :scroll) })
        return Hashie::Mash.new(
          total: response.dig("hits", "total", "value"),
          results: response.dig("hits", "hits").map { |r| r["_source"] },
          scroll_id: response["_scroll_id"],
        )
      # handle expired scroll_id (Elasticsearch returns this error)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        return Hashie::Mash.new(
          total: 0,
          results: [],
          scroll_id: nil,
        )
      end
    end

    options[:page] ||= {}
    options[:page][:number] ||= 1
    options[:page][:size] ||= 25

    aggregations = if options[:totals_agg] == "provider"
      provider_aggregations
    elsif options[:totals_agg] == "client"
      client_aggregations
    elsif options[:totals_agg] == "client_export"
      client_export_aggregations
    elsif options[:totals_agg] == "prefix"
      prefix_aggregations
    elsif options[:client_type] == "igsnCatalog"
      query_aggregations(disable_facets: options[:disable_facets]).merge(self.igsn_id_catalog_aggregations)
    else
      query_aggregations(disable_facets: options[:disable_facets])
    end

    # Cursor nav uses search_after, this should always be an array of values that match the sort.
    if options.fetch(:page, {}).key?(:cursor)
      # make sure we have a valid cursor
      cursor = [0, ""]
      if options.dig(:page, :cursor).is_a?(Array)
        timestamp, uid = options.dig(:page, :cursor)
        cursor = [timestamp.to_i, uid.to_s]
      elsif options.dig(:page, :cursor).is_a?(String)
        timestamp, uid = options.dig(:page, :cursor).split(",")
        cursor = [timestamp.to_i, uid.to_s]
      end

      from = 0
      search_after = cursor
      sort = [{ created: "asc", uid: "asc" }]
    else
      from = ((options.dig(:page, :number) || 1) - 1) * (options.dig(:page, :size) || 25)
      search_after = nil
      sort = options[:sort]
    end

    # make sure field name uses underscore
    # escape forward slash, but not other Elasticsearch special characters
    if query.present?
      query = query.gsub(/publicationYear/, "publication_year")
      query = query.gsub(/relatedIdentifiers/, "related_identifiers")
      query = query.gsub(/relatedItems/, "related_items")
      query = query.gsub(/rightsList/, "rights_list")
      query = query.gsub(/fundingReferences/, "funding_references")
      query = query.gsub(/geoLocations/, "geo_locations")
      query = query.gsub(/version:/, "version_info:")
      query = query.gsub(/landingPage/, "landing_page")
      query = query.gsub(/contentUrl/, "content_url")
      query = query.gsub(/citationCount/, "citation_count")
      query = query.gsub(/viewCount/, "view_count")
      query = query.gsub(/downloadCount/, "download_count")
      query = query.gsub(/(publisher\.)(name|publisherIdentifier|publisherIdentifierScheme|schemeUri|lang)/, 'publisher_obj.\2')
      query = query.gsub("/", "\\/")
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
    should = []
    minimum_should_match = 0

    filter << { terms: { doi: options[:ids].map(&:upcase) } } if options[:ids].present?
    filter << { term: { resource_type_id: options[:resource_type_id].underscore.dasherize } } if options[:resource_type_id].present?
    filter << { terms: { "types.resourceType": options[:resource_type].split(",") } } if options[:resource_type].present?
    if options[:provider_id].present?
      options[:provider_id].split(",").each { |id|
        should << { term: { "provider_id": { value: id, case_insensitive: true } } }
      }
      minimum_should_match = 1
    end
    if options[:client_id].present?
      options[:client_id].split(",").each { |id|
        should << { term: { "client_id": { value: id, case_insensitive: true } } }
      }
      minimum_should_match = 1
    end
    filter << { terms: { agency: options[:agency].split(",").map(&:downcase) } } if options[:agency].present?
    filter << { terms: { prefix: options[:prefix].to_s.split(",") } } if options[:prefix].present?
    filter << { terms: { language: options[:language].to_s.split(",").map(&:downcase) } } if options[:language].present?
    filter << { term: { uid: options[:uid] } } if options[:uid].present?
    filter << { range: { created: { gte: "#{options[:created].split(',').min}||/y", lte: "#{options[:created].split(',').max}||/y", format: "yyyy" } } } if options[:created].present?
    filter << { range: { publication_year: { gte: "#{options[:published].split(',').min}||/y", lte: "#{options[:published].split(',').max}||/y", format: "yyyy" } } } if options[:published].present?
    filter << { term: { schema_version: "http://datacite.org/schema/kernel-#{options[:schema_version]}" } } if options[:schema_version].present?
    filter << { terms: { "subjects.subject": options[:subject].split(",") } } if options[:subject].present?
    if options[:pid_entity].present?
      filter << { term: { "subjects.subjectScheme": "PidEntity" } }
      filter << { terms: { "subjects.subject": options[:pid_entity].split(",").map(&:humanize) } }
    end
    if options[:field_of_science].present?
      filter << { term: { "subjects.subjectScheme": "Fields of Science and Technology (FOS)" } }
      filter << { terms: { "subjects.subject": options[:field_of_science].split(",").map { |s| "FOS: " + s.humanize } } }
    end
    if options[:field_of_science_repository].present?
      filter << { terms: { "fields_of_science_repository": options[:field_of_science_repository].split(",").map { |s| s.humanize } } }
    end
    if options[:field_of_science_combined].present?
      filter << { terms: { "fields_of_science_combined": options[:field_of_science_combined].split(",").map { |s| s.humanize } } }
    end
    filter << { terms: { "rights_list.rightsIdentifier" => options[:license].split(",") } } if options[:license].present?
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
    filter << { exists: { field: "landing_page.checked" } } if options[:link_checked].present?
    filter << { term: { "landing_page.hasSchemaOrg": options[:link_check_has_schema_org] } } if options[:link_check_has_schema_org].present?
    filter << { term: { "landing_page.bodyHasPid": options[:link_check_body_has_pid] } } if options[:link_check_body_has_pid].present?
    filter << { exists: { field: "landing_page.schemaOrgId" } } if options[:link_check_found_schema_org_id].present?
    filter << { exists: { field: "landing_page.dcIdentifier" } } if options[:link_check_found_dc_identifier].present?
    filter << { exists: { field: "landing_page.citationDoi" } } if options[:link_check_found_citation_doi].present?
    filter << { range: { "landing_page.redirectCount": { "gte": options[:link_check_redirect_count_gte] } } } if options[:link_check_redirect_count_gte].present?
    filter << { terms: { aasm_state: options[:state].to_s.split(",") } } if options[:state].present?
    filter << { range: { registered: { gte: "#{options[:registered].split(',').min}||/y", lte: "#{options[:registered].split(',').max}||/y", format: "yyyy" } } } if options[:registered].present?
    filter << { term: { "consortium_id": { value: options[:consortium_id], case_insensitive: true  } } } if options[:consortium_id].present?
    # TODO align PID parsing
    filter << { term: { "client.re3data_id" => doi_from_url(options[:re3data_id]) } } if options[:re3data_id].present?
    filter << { term: { "client.opendoar_id" => options[:opendoar_id] } } if options[:opendoar_id].present?
    filter << { terms: { "client.certificate" => options[:certificate].split(",") } } if options[:certificate].present?
    filter << { term: { "creators.nameIdentifiers.nameIdentifier" => "https://orcid.org/#{orcid_from_url(options[:user_id])}" } } if options[:user_id].present?
    filter << { term: { "creators.nameIdentifiers.nameIdentifierScheme" => "ORCID" } } if options[:has_person].present?
    filter << { term: { "client.client_type" =>  options[:client_type] } } if options[:client_type]
    filter << { term: { "types.resourceTypeGeneral" => "PhysicalObject" } } if options[:client_type] == "igsnCatalog"

    # match either one of has_affiliation, has_organization, or has_funder
    if options[:has_organization].present?
      should << { term: { "creators.nameIdentifiers.nameIdentifierScheme" => "ROR" } }
      should << { term: { "contributors.nameIdentifiers.nameIdentifierScheme" => "ROR" } }
      minimum_should_match = 1
    end
    if options[:has_affiliation].present?
      should << { term: { "creators.affiliation.affiliationIdentifierScheme" => "ROR" } }
      should << { term: { "contributors.affiliation.affiliationIdentifierScheme" => "ROR" } }
      minimum_should_match = 1
    end
    if options[:has_funder].present?
      should << { term: { "funding_references.funderIdentifierType" => "Crossref Funder ID" } }
      minimum_should_match = 1
    end
    if options[:has_member].present?
      should << { exists: { field: "provider.ror_id" } }
      minimum_should_match = 1
    end

    # match either ROR ID or Crossref Funder ID if either organization_id, affiliation_id,
    # funder_id or member_id is a query parameter
    if options[:organization_id].present?
      # should << { term: { "creators.nameIdentifiers.nameIdentifier" => "https://#{ror_from_url(options[:organization_id])}" } }
      # should << { term: { "contributors.nameIdentifiers.nameIdentifier" => "https://#{ror_from_url(options[:organization_id])}" } }
      should << { term: { "organization_id" => ror_from_url(options[:organization_id]) } }
      minimum_should_match = 1
    end
    if options[:affiliation_id].present?
      should << { term: { "affiliation_id" => ror_from_url(options[:affiliation_id]) } }
      minimum_should_match = 1
    end
    if options[:funder_id].present?
      should << { terms: { "funding_references.funderIdentifier" => options[:funder_id].split(",").map { |f| "https://doi.org/#{doi_from_url(f)}" } } }
      minimum_should_match = 1
    end
    if options[:member_id].present?
      should << { term: { "provider.ror_id" => "https://#{ror_from_url(options[:member_id])}" } }
      minimum_should_match = 1
    end

    must_not << { terms: { agency: ["crossref", "kisti", "medra", "jalc", "istic", "airiti", "cnki", "op"] } } if options[:exclude_registration_agencies]

    # ES query can be optionally defined in different ways
    # So here we build it differently based upon options
    # This is mostly useful when trying to wrap it in a function_score query
    es_query = {}

    # The main bool query with filters
    bool_query = {
      must: must,
      must_not: must_not,
      filter: filter,
      should: should,
      minimum_should_match: minimum_should_match,
    }

    # Function score is used to provide varying score to return different values
    # We use the bool query above as our principle query
    # Then apply additional function scoring as appropriate
    # Note this can be performance intensive.
    function_score = {
      query: {
        bool: bool_query,
      },
      random_score: {
        "seed": Rails.env.test? ? "random_1234" : "random_#{rand(1...100000)}",
      },
    }

    if options[:random].present?
      es_query["function_score"] = function_score
      # Don't do any sorting for random results
      sort = nil
    else
      es_query["bool"] = bool_query
    end

    # Sample grouping is optional included aggregation
    if options[:sample_group].present?
      aggregations[:samples] = {
        terms: {
          field: options[:sample_group],
          size: 10000,
        },
        aggs: {
          "samples_hits": {
            top_hits: {
              size: options[:sample_size].presence || 1,
            },
          },
        },
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
        index: index_name,
        scroll: options.dig(:page, :scroll),
        body: {
          size: options.dig(:page, :size),
          sort: sort,
          query: es_query,
          aggregations: aggregations,
          track_total_hits: true,
        }.compact,
      )
      Hashie::Mash.new(
        total: response.dig("hits", "total", "value"),
        results: response.dig("hits", "hits").map { |r| r["_source"] },
        scroll_id: response["_scroll_id"],
      )
    elsif options.fetch(:page, {}).key?(:cursor)
      __elasticsearch__.search({
        size: options.dig(:page, :size),
        search_after: search_after,
        sort: sort,
        query: es_query,
        aggregations: aggregations,
        track_total_hits: true,
      }.compact)
    else
      __elasticsearch__.search({
        size: options.dig(:page, :size),
        from: from,
        sort: sort,
        query: es_query,
        aggregations: aggregations,
        track_total_hits: true,
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
    "Started indexing DOI #{doi.doi}."
  end

  def self.import_one(doi_id: nil, id: nil)
    if doi_id
      doi = Doi.where(doi: doi_id).first
    else
      doi = Doi.where(id: id).first
    end

    if doi.blank?
      message = "[MySQL] Error importing DOI #{doi_id}: not found"
      Rails.logger.error message
      return message
    end

    string = doi.current_metadata.present? ? doi.clean_xml(doi.current_metadata.xml) : nil
    if string.blank?
      message = "[MySQL] No metadata for DOI #{doi.doi} found: " + doi.current_metadata.inspect
      Rails.logger.error message
      return message
    end

    meta = doi.read_datacite(string: string, sandbox: doi.sandbox)
    attrs = %w(creators contributors titles publisher publication_year types descriptions container sizes formats language dates identifiers related_identifiers related_items funding_references geo_locations rights_list subjects content_url version_info).map do |a|
      [a.to_sym, meta[a]]
    end.to_h.merge(schema_version: meta["schema_version"] || "http://datacite.org/schema/kernel-4", xml: string, version: doi.version.to_i + 1)

    # update_attributes will trigger validations and Elasticsearch indexing
    doi.update(attrs)
    message = "[MySQL] Imported metadata for DOI " + doi.doi + "."
    Rails.logger.info message
    message
  rescue TypeError, NoMethodError, RuntimeError, ActiveRecord::StatementInvalid, ActiveRecord::LockWaitTimeout => e
    if doi.present?
      message = "[MySQL] Error importing metadata for " + doi.doi + ": " + e.message
    else
      message = "[MySQL] Error importing metadata: " + e.message
      Raven.capture_exception(e)
    end

    Rails.logger.error message
    message
  end

  def uid
    doi.downcase
  end

  def resource_type_id
    r = handle_resource_type(types) # types.to_h["resourceTypeGeneral"]
    r.underscore.dasherize if RESOURCE_TYPES_GENERAL[r].present?
  rescue TypeError
    nil
  end

  def resource_type_id_and_name
    r = handle_resource_type(types) # types.to_h["resourceTypeGeneral"]
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
    view_events.pluck(:occurred_at, :total).
      map { |v| { "yearMonth" => v[0].present? ? v[0].utc.iso8601[0..6] : nil, "total" => v[1] } }.
      sort_by { |h| h["yearMonth"] }
  end

  def download_count
    download_events.pluck(:total).inject(:+).to_i
  end

  def downloads_over_time
    download_events.pluck(:occurred_at, :total).
      map { |v| { "yearMonth" => v[0].present? ? v[0].utc.iso8601[0..6] : nil, "total" => v[1] } }.
      sort_by { |h| h["yearMonth"] }
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
    citation_events.pluck(:occurred_at, :source_doi).uniq { |v| v[1] }.
      group_by { |v| v[0].utc.iso8601[0..3] }.
      map { |k, v| { "year" => k, "total" => v.length } }.
      sort_by { |h| h["year"] }
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

  def other_relation_events
    Event.events_involving(doi, Event::OTHER_RELATION_TYPES)
  end

  def other_relation_ids
    other_relation_events.map do |e|
      e.doi
    end.flatten.uniq - [doi.downcase]
  end

  def other_relation_count
    other_relation_ids.length
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

  def self.convert_affiliations(options = {})
    from_id = (options[:from_id] || Doi.minimum(:id)).to_i
    until_id = (options[:until_id] || Doi.maximum(:id)).to_i

    # get every id between from_id and until_id
    (from_id..until_id).step(500).each do |id|
      DoiConvertAffiliationByIdJob.perform_later(options.merge(id: id))
      Rails.logger.info "Queued converting affiliations for DOIs with IDs starting with #{id}." unless Rails.env.test?
    end

    "Queued converting #{(from_id..until_id).to_a.length} affiliations."
  end

  def self.convert_affiliation_by_id(options = {})
    return nil if options[:id].blank?

    id = options[:id].to_i
    count = 0

    Doi.where(id: id..(id + 499)).find_each do |doi|
      should_update = false
      creators = Array.wrap(doi.creators).map do |c|
        if !c.is_a?(Hash)
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
        if !c.is_a?(Hash)
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

      unless Array.wrap(doi.creators).all? { |c| c.is_a?(Hash) && c["affiliation"].is_a?(Array) && c["affiliation"].all? { |a| a.is_a?(Hash) } } && Array.wrap(doi.contributors).all? { |c| c.is_a?(Hash) && c["affiliation"].is_a?(Array) && c["affiliation"].all? { |a| a.is_a?(Hash) } }
        Rails.logger.error "[MySQL] Error converting affiliations for doi #{doi.doi}: creators #{doi.creators.inspect} contributors #{doi.contributors.inspect}."
        fail TypeError, "Affiliation for doi #{doi.doi} is of wrong type" if Rails.env.test?
      end
    end

    Rails.logger.info "[MySQL] Converted affiliations for #{count} DOIs with IDs #{id} - #{id + 499}." if count > 0

    count
  rescue TypeError, ActiveRecord::ActiveRecordError, ActiveRecord::LockWaitTimeout => e
    Rails.logger.error "[MySQL] Error converting affiliations for DOIs with IDs #{id} - #{id + 499}: #{e.message}."
    count
  end

  def self.convert_publishers(options = {})
    from_id = (options[:from_id] || Doi.minimum(:id)).to_i
    until_id = (options[:until_id] || Doi.maximum(:id)).to_i

    # get every id between from_id and until_id
    (from_id..until_id).step(500).each do |id|
      DoiConvertPublisherByIdJob.perform_later(options.merge(id: id))
      Rails.logger.info "Queued converting publisher to publisher_obj for DOIs with IDs starting with #{id}." unless Rails.env.test?
    end

    "Queued converting #{(from_id..until_id).size} publishers."
  end

  def self.convert_publisher_by_id(options = {})
    return nil if options[:id].blank?

    id = options[:id].to_i
    count = 0

    Doi.where(id: id..(id + 499)).find_each do |doi|
      should_update = true

      if should_update
        Doi.auditing_enabled = false
        doi.update_columns(publisher_obj: doi.publisher)
        Doi.auditing_enabled = true

        count += 1
      end
    end

    Rails.logger.info "[MySQL] Converted publishers for #{count} DOIs with IDs #{id} - #{id + 499}." if count > 0

    count
  rescue TypeError, ActiveRecord::ActiveRecordError, ActiveRecord::LockWaitTimeout => e
    Rails.logger.error "[MySQL] Error converting publishers for DOIs with IDs #{id} - #{id + 499}: #{e.message}."
    count
  end

  def self.convert_containers(options = {})
    from_id = (options[:from_id] || Doi.minimum(:id)).to_i
    until_id = (options[:until_id] || Doi.maximum(:id)).to_i

    # get every id between from_id and until_id
    (from_id..until_id).step(500).each do |id|
      DoiConvertContainerByIdJob.perform_later(options.merge(id: id))
      Rails.logger.info "Queued converting containers for DOIs with IDs starting with #{id}." unless Rails.env.test?
    end

    "Queued converting #{(from_id..until_id).to_a.length} containers."
  end

  def self.convert_container_by_id(options = {})
    return nil if options[:id].blank?

    id = options[:id].to_i
    count = 0

    Doi.where(id: id..(id + 499)).find_each do |doi|
      should_update = false

      if doi.container.nil?
        should_update = true
        container = {}
      elsif !doi.container.is_a?(Hash)
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
          "lastPage" => doi.container["lastPage"],
        }.compact
      end

      if should_update
        doi.update_columns(container: container)
        count += 1
      end
    end

    Rails.logger.info "[MySQL] Converted containers for #{count} DOIs with IDs #{id} - #{id + 499}." if count > 0

    count
  rescue TypeError, ActiveRecord::ActiveRecordError, ActiveRecord::LockWaitTimeout => e
    Rails.logger.error "[MySQL] Error converting containers for DOIs with IDs #{id} - #{id + 499}: #{e.message}."
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

  def related_items=(value)
    write_attribute(:related_items, Array.wrap(value))
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

  def _fos_filter(subject_array)
    Array.wrap(subject_array).select { |sub|
      sub.dig("subjectScheme") == FIELD_OF_SCIENCE_SCHEME
    }.map do |fos|
      fos["subject"].gsub("FOS: ", "")
    end
  end

  def fields_of_science
    _fos_filter(subjects).uniq
  end

  def fields_of_science_repository
    _fos_filter(client&.subjects).uniq
  end

  def fields_of_science_combined
    fields_of_science | fields_of_science_repository
  end

  def client_id_and_name
    "#{client_id}:#{client.name}" if client.present?
  end

  def client_id=(value)
    r = ::Client.where(symbol: value).first
    fail ActiveRecord::RecordNotFound if r.blank?

    write_attribute(:datacentre, r.id)
  end

  def provider_id
    client.provider.symbol.downcase if client.present?
  end

  def provider_id_and_name
    "#{provider_id}:#{client.provider.name}" if client.present?
  end

  def consortium_id
    client.provider.consortium_id.downcase if client.present? && client.provider.consortium_id.present?
  end

  def related_dois
    Doi::Indexer::RelatedDoiIndexer.new(related_identifiers).as_indexed_json
  end

  def related_dmp_ids
    Array.wrap(related_identifiers).select { |related_identifier|
      related_identifier["relatedIdentifierType"] == "DOI"
    }.select { |related_identifier|
      related_identifier.fetch("resourceTypeGeneral", nil) == "OutputManagementPlan"
    }.map do |related_identifier|
      related_identifier["relatedIdentifier"]
    end
  end

  def related_dmp_works
    Doi.where(doi: related_dmp_ids)
  end

  def related_dmp_organization_and_affiliation_id
    related_dmp_works.reduce([]) do |sum, dmp|
      sum.concat(dmp.organization_id)
      sum.concat(dmp.affiliation_id)

      sum
    end
  end

  def sponsor_contributors
    Array.wrap(contributors).select { |c|
      c["contributorType"] == "Sponsor"
    }
  end


  def person_id
    (Array.wrap(creators) + Array.wrap(contributors)).reduce([]) do |sum, c|
      Array.wrap(c.fetch("nameIdentifiers", nil)).each do |name_identifier|
        if name_identifier.is_a?(Hash) && name_identifier.fetch("nameIdentifierScheme", nil) == "ORCID" && name_identifier.fetch("nameIdentifier", nil).present?
          sum << orcid_as_url(
            orcid_from_url(name_identifier.fetch("nameIdentifier", nil))
          )
        end
      end
      sum.uniq
    end
  end

  def organization_id
    organization_ids = (Array.wrap(creators) + Array.wrap(contributors)).reduce([]) do |sum, c|
      Array.wrap(c.fetch("nameIdentifiers", nil)).each do |name_identifier|
        if name_identifier.is_a?(Hash) && name_identifier.fetch("nameIdentifierScheme", nil) == "ROR" && name_identifier.fetch("nameIdentifier", nil).present?
          sum << ror_from_url(name_identifier.fetch("nameIdentifier", nil))
        end
      end
      sum
    end
    organization_ids << ror_from_url(publisher["publisherIdentifier"]) if publisher_has_ror?
    organization_ids.uniq
  end

  def publisher_has_ror?
    publisher.is_a?(Hash) &&
      publisher.fetch("publisherIdentifierScheme", nil) == "ROR" &&
      publisher.fetch("publisherIdentifier", nil).present?
  end

  def fair_organization_id
    (Array.wrap(creators) + sponsor_contributors).reduce([]) do |sum, c|
      Array.wrap(c.fetch("nameIdentifiers", nil)).each do |name_identifier|
        if name_identifier.is_a?(Hash) && name_identifier.fetch("nameIdentifierScheme", nil) == "ROR" && name_identifier.fetch("nameIdentifier", nil).present?
          sum << ror_from_url(name_identifier.fetch("nameIdentifier", nil))
        end
      end
      sum.uniq
    end
  end

  def affiliation_id
    (Array.wrap(creators) + Array.wrap(contributors)).reduce([]) do |sum, c|
      Array.wrap(c.fetch("affiliation", nil)).each do |affiliation|
        sum << ror_from_url(affiliation.fetch("affiliationIdentifier", nil)) if affiliation.is_a?(Hash) && affiliation.fetch("affiliationIdentifierScheme", nil) == "ROR" && affiliation.fetch("affiliationIdentifier", nil).present?
      end
      sum.uniq
    end
  end

  def fair_affiliation_id
    (Array.wrap(creators) + sponsor_contributors).reduce([]) do |sum, c|
      Array.wrap(c.fetch("affiliation", nil)).each do |affiliation|
        sum << ror_from_url(affiliation.fetch("affiliationIdentifier", nil)) if affiliation.is_a?(Hash) && affiliation.fetch("affiliationIdentifierScheme", nil) == "ROR" && affiliation.fetch("affiliationIdentifier", nil).present?
      end
      sum.uniq
    end
  end

  def affiliation_id_and_name
    (Array.wrap(creators) + Array.wrap(contributors)).reduce([]) do |sum, c|
      Array.wrap(c.fetch("affiliation", nil)).each do |affiliation|
        sum << "#{ror_from_url(affiliation.fetch('affiliationIdentifier', nil))}:#{affiliation.fetch('name', nil)}" if affiliation.is_a?(Hash) && affiliation.fetch("affiliationIdentifierScheme", nil) == "ROR" && affiliation.fetch("affiliationIdentifier", nil).present?
      end
      sum.uniq
    end
  end

  def fair_affiliation_id_and_name
    (Array.wrap(creators) + sponsor_contributors).reduce([]) do |sum, c|
      Array.wrap(c.fetch("affiliation", nil)).each do |affiliation|
        sum << "#{ror_from_url(affiliation.fetch('affiliationIdentifier', nil))}:#{affiliation.fetch('name', nil)}" if affiliation.is_a?(Hash) && affiliation.fetch("affiliationIdentifierScheme", nil) == "ROR" && affiliation.fetch("affiliationIdentifier", nil).present?
      end
      sum.uniq
    end
  end


  def prefix
    doi.split("/", 2).first if doi.present?
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
    %w(registered findable).include?(aasm_state) || provider_id == "europ" || type == "OtherDoi"
  end

  def validatable?
    %w(registered findable).include?(aasm_state) || should_validate || only_validate
  end

  # update URL in handle system for registered and findable state
  # providers europ, and DOI registration agencies do their own handle registration, so fetch url from handle system instead
  def update_url
    return nil if current_user.nil? || !is_registered_or_findable?

    if %w(europ).include?(provider_id) || type == "OtherDoi"
      UrlJob.perform_later(doi)
    # TODO better define conditions for updating handle system
    # elsif url_changed? || changes["aasm_state"] == ["draft", "findable"] || changes["aasm_state"] == ["draft", "registered"]
    else
      register_url
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
      "updated" => date_updated,
    }

    { "id" => doi, "type" => "dois", "attributes" => attributes }
  end

  def current_metadata
    metadata.order("metadata.created DESC").first
  end

  def metadata_version
    current_metadata ? current_metadata.metadata_version : 0
  end

  def current_media
    media.order("media.created DESC").first
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

  def primary_title
    Array.wrap(Array.wrap(titles).first)
  end

  def event=(value)
    send(value) if %w(register publish hide show).include?(value)
  end

  def check_url
    unless url.blank? || client.blank? || match_url_with_domains(url: url, domains: client.domains)
      errors.add(:url, "URL #{url} is not allowed by repository #{client.uid} domain settings.")
    end
  end

  def check_dates
    Array.wrap(dates).each do |d|
      errors.add(:dates, "Date #{d} should be an object instead of a string.") unless d.is_a?(Hash)
      # errors.add(:dates, "Date #{d["date"]} is not a valid date in ISO8601 format.") unless Date.edtf(d["date"]).present?
    end
  end

  def check_rights_list
    Array.wrap(rights_list).each do |r|
      errors.add(:rights_list, "Rights '#{r}' should be an object instead of a string.") unless r.is_a?(Hash)
      errors.add(:rights_list, "Rights should not have a length of more than 2000 characters.") if r["rights"].to_s.length > 2000
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
      if schema_version == "http://datacite.org/schema/kernel-4"
        errors.add(:contributors, "Contributor type #{c['contributorType']} is not supported in schema 4.") unless %w(ContactPerson DataCollector DataCurator DataManager Distributor Editor HostingInstitution Other Producer ProjectLeader ProjectManager ProjectMember RegistrationAgency RegistrationAuthority RelatedPerson ResearchGroup RightsHolder Researcher Sponsor Supervisor Translator WorkPackageLeader).include?(c["contributorType"])
      end
    end
  end

  def check_identifiers
    Array.wrap(identifiers).each do |i|
      errors.add(:identifiers, "Identifier '#{i}' should be an object instead of a string.") unless i.is_a?(Hash)
      errors.add(:identifiers, "IdentifierType DOI not supported in identifiers property. Use id or related identifier.") if i["identifierType"] == "DOI"
    end
  end

  def check_related_identifiers
    Array.wrap(related_identifiers).each do |r|
      errors.add(:related_identifiers, "Related identifier '#{r}' should be an object instead of a string.") unless r.is_a?(Hash)
    end
  end

  def check_related_items
    Array.wrap(related_items).each do |r|
      errors.add(:related_items, "Related item '#{r}' should be an object instead of a string.") unless r.is_a?(Hash)
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

  def check_language
    errors.add(:language, "Language #{language} is in an invalid format.") if !language.match?(/^[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*$/)
  end

  # To be used for isolated clean up of errored individual DOIs
  # Should only be used when the DOI is not registered in the handle system.
  def self.delete_by_doi(doi, options = {})
    DeleteJob.perform_later(doi)
    "DOI #{doi} will be deleted"
  end

  def self.hide_by_doi(doi, options = {})
    HideJob.perform_later(doi)
    "DOI #{doi} will be hidden (change state from findable => registered)."
  end

  def self.delete_dois_by_prefix(prefix, options = {})
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

      while !response.results.results.empty?
        response = Doi.query(nil, prefix: prefix, page: { size: size, cursor: cursor })
        break if response.results.results.empty?

        Rails.logger.info "Deleting #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          DeleteJob.perform_later(d.doi)
        end
      end
    end

    response.results.total
  end

  # To be used after DOIs were transferred to another DOI RA
  # 'Hide' dois by moving state from findable to registered.
  def self.hide_dois_by_prefix(prefix, options = {})
    if prefix.blank?
      Rails.logger.error "[Error] No prefix provided."
      return nil
    end

    # query = options[:query] || "*"
    # size = (options[:size] || 1000).to_i
    size = (options[:size] || 1000).to_i

    response = Doi.query(nil, prefix: prefix, page: { size: 1, cursor: [] })
    Rails.logger.info "#{response.results.total} DOIs found for prefix #{prefix}."

    if prefix && response.results.total > 0
      # walk through results using cursor
      cursor = []

      while !response.results.results.empty?
        response = Doi.query(nil, prefix: prefix, page: { size: size, cursor: cursor })
        break if response.results.results.empty?

        Rails.logger.info "Hiding #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          HideJob.perform_later(d.doi)
        end
      end
    end

    response.results.total
  end

  # register DOIs in the handle system that have not been registered yet
  # provider europ registers their DOIs in the handle system themselves and are ignored
  def self.set_handle
    response = Doi.query("-registered:* +url:* -aasm_state:draft -provider_id:europ -agency:crossref", page: { size: 1, cursor: [] })
    message = "#{response.results.total} DOIs found that are not registered in the Handle system."

    if response.results.total > 0
      # walk through results using cursor
      cursor = []

      while !response.results.results.empty?
        response = Doi.query("-registered:* +url:* -aasm_state:draft -provider_id:europ -agency:crossref", page: { size: 1000, cursor: cursor })
        break if response.results.results.empty?

        Rails.logger.info "[Handle] Register #{response.results.results.length} DOIs in the handle system starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          HandleJob.perform_later(d.doi)
        end
      end
    end

    message
  end

  def self.set_url
    response = Doi.query("-url:* (-aasm_status:draft)", page: { size: 1, cursor: [] })
    message = "#{response.results.total} DOIs with no URL found in the database."

    if response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length.postive?
        response = Doi.query("-url:* (-aasm_status:draft)", page: { size: 1000, cursor: cursor })
        break unless response.results.results.length.positive?

        Rails.logger.info "[Handle] Update URL for #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          UrlJob.perform_later(d.doi)
        end
      end
    end

    message
  end

  def self.set_minted
    response = Doi.query("+aasm_state:draft +url:*", page: { size: 1, cursor: [] })
    message = "#{response.results.total} draft DOIs with URL found in the database."

    if response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length.positive?
        response = Doi.query("+aasm_state:draft +url:*", page: { size: 1000, cursor: cursor })
        break unless response.results.results.length.positive?

        Rails.logger.info "[MySQL] Set minted for #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          UrlJob.perform_later(d.doi)
        end
      end
    end

    message
  end

  def self.transfer(options = {})
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

    response = Doi.query(query, client_id: options[:client_id].downcase, page: { size: 1, cursor: [] })
    Rails.logger.info "[Transfer] #{response.results.total} DOIs found for client #{options[:client_id]}."

    if options[:client_id] && options[:client_target_id] && response.results.total > 0
      # walk through results using cursor
      cursor = []

      while response.results.results.length.positive?
        response = Doi.query(nil, client_id: options[:client_id].downcase, page: { size: size, cursor: cursor })
        break unless response.results.results.length.positive?

        Rails.logger.info "[Transfer] Transferring #{response.results.results.length} DOIs starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]

        response.results.results.each do |d|
          TransferJob.perform_later(d.doi, client_target_id: options[:client_target_id])
        end
      end
    end

    response.results.total
  end

  # Transverses the index in batches and using the cursor pagination and executes a Job that matches the query and filter
  # Options:
  # +filter+:: paramaters to filter the index
  # +label+:: String to output in the logs printout
  # +query+:: ES query to filter the index
  # +job_name+:: Acive Job class name of the Job that would be executed on every matched results
  def self.loop_through_dois(options = {})
    size = (options[:size] || 1000).to_i
    cursor = options[:cursor] || []
    filter = options[:filter] || {}
    label = options[:label] || ""
    options[:job_name] ||= ""
    query = options[:query].presence

    response = Doi.query(query, filter.merge(page: { size: 1, cursor: [] }))
    message = "#{label} #{response.results.total} Dois."

    # walk through results using cursor
    if response.results.total.positive?
      while response.results.results.length.positive?
        response = Doi.query(query, filter.merge(page: { size: size, cursor: cursor }))
        break unless response.results.results.length.positive?

        Rails.logger.info "#{label} #{response.results.results.length} Dois starting with _id #{response.results.to_a.first[:_id]}."
        cursor = response.results.to_a.last[:sort]
        Rails.logger.info "#{label} Cursor: #{cursor} "

        ids = response.results.results.map(&:uid)
        LoopThroughDoisJob.perform_later(ids, options)
      end
    end

    message
  end

  # save to metadata table when xml has changed
  def save_metadata
    metadata.build(doi: self, xml: xml, namespace: schema_version) if xml.present? && xml_changed?
  end

  def set_defaults
    self.is_active = aasm_state == "findable" ? "\x01" : "\x00"
    self.version = version.present? ? version + 1 : 1
    self.updated = Time.zone.now.utc.iso8601
    self.source = "api" if source.blank?
  end

  def update_agency
    if agency.blank? || agency.casecmp?("datacite")
      self.agency = "datacite"
      self.type = "DataciteDoi"
    elsif agency.casecmp?("crossref")
      self.agency = "crossref"
      self.type = "OtherDoi"
    elsif agency.casecmp?("kisti")
      self.agency = "kisti"
      self.type = "OtherDoi"
    elsif agency.casecmp?("medra")
      self.agency = "medra"
      self.type = "OtherDoi"
    elsif agency.casecmp?("istic")
      self.agency = "istic"
      self.type = "OtherDoi"
    elsif agency.casecmp?("jalc")
      self.agency = "jalc"
      self.type = "OtherDoi"
    elsif agency.casecmp?("airiti")
      self.agency = "airiti"
      self.type = "OtherDoi"
    elsif agency.casecmp?("cnki")
      self.agency = "cnki"
      self.type = "OtherDoi"
    elsif agency.casecmp?("op")
      self.agency = "op"
      self.type = "OtherDoi"
    else
      self.agency = "datacite"
      self.type = "DataciteDoi"
    end
  end

  def update_language
    lang = language.to_s.split("-").first
    entry = ISO_639.find_by_code(lang) || ISO_639.find_by_english_name(lang.upcase_first)
    self.language =
      if entry.present? && entry.alpha2.present?
        entry.alpha2
      elsif language.match?(/^[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*$/)
        language
      end
  end

  def update_field_of_science
    self.subjects = Array.wrap(subjects).reduce([]) do |sum, subject|
      if subject.is_a?(String)
        sum += name_to_fos(subject)
      elsif subject.is_a?(Hash)
        sum += hsh_to_fos(subject)
      end

      sum
    end.uniq
  end

  def update_rights_list
    self.rights_list = Array.wrap(rights_list).map do |r|
      if r.blank?
        nil
      elsif r.is_a?(String)
        name_to_spdx(r)
      elsif r.is_a?(Hash)
        hsh_to_spdx(r)
      end
    end.compact
  end

  def update_identifiers
    self.identifiers = Array.wrap(identifiers).reject { |i| i["identifierType"] == "DOI" }
  end

  def update_types
    return nil unless types.is_a?(Hash)

    res = types["resourceType"].to_s.underscore.camelcase
    resgen = types["resourceTypeGeneral"].to_s.dasherize
    schema_org = Bolognese::Utils::CR_TO_SO_TRANSLATIONS[res] || Bolognese::Utils::DC_TO_SO_TRANSLATIONS[resgen] || "CreativeWork"

    self.types = types.reverse_merge(
      "schemaOrg" => schema_org,
      "citeproc" => Bolognese::Utils::CR_TO_CP_TRANSLATIONS[res] || Bolognese::Utils::SO_TO_CP_TRANSLATIONS[schema_org] || "article",
      "bibtex" => Bolognese::Utils::CR_TO_BIB_TRANSLATIONS[res] || Bolognese::Utils::SO_TO_BIB_TRANSLATIONS[schema_org] || "misc",
      "ris" => Bolognese::Utils::CR_TO_RIS_TRANSLATIONS[res] || Bolognese::Utils::DC_TO_RIS_TRANSLATIONS[resgen] || "GEN",
    ).compact
  end

  def update_publisher
    case publisher_before_type_cast
    when Hash
      update_publisher_from_hash
    when String
      update_publisher_from_string
    else
      reset_publishers
    end
  end

  def publisher
    read_attribute("publisher_obj")
  end

  def self.repair_landing_page(id: nil)
    if id.blank?
      Rails.logger.error "[Error] No id provided."
      return nil
    end

    doi = Doi.where(id: id).first
    if doi.nil?
      Rails.logger.error "[Error] DOI with #{id} not found."
      return nil
    end

    begin
      landing_page = doi.landing_page

      # Schema.org ID's can be an array, they must always be a single keyword, so extract where possible.
      schema_org_id = landing_page["schemaOrgId"]

      if schema_org_id.is_a?(Array)
        # There shouldn't be anymore than a singular entry, but even if there are more, it's not something we can handle here
        # Instead just try and grab the first value of the first entry.
        landing_page["schemaOrgId"] = schema_org_id[0]["value"]
      end

      # Update with changes
      doi.update_columns("landing_page": landing_page)

      "Updated landing page data for DOI " + doi.doi
    rescue TypeError, NoMethodError => e
      "Error updating landing page data for DOI " + doi.doi + " - " + e.message
    end
  end

  def self.migrate_landing_page(_options = {})
    Rails.logger.info "Starting migration"

    # Handle camel casing first.
    Doi.where.not("last_landing_page_status_result" => nil).find_each do |doi|
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
      result = result.transform_keys { |k| mappings[k] || k }
      # doi.update_columns("last_landing_page_status_result": result)

      # Do a fix of the stored download Latency
      # Sometimes was floating point precision, we dont need this
      download_latency = result["downloadLatency"]
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
        "error" => result["error"],
        "redirectCount" => result["redirectCount"],
        "redirectUrls" => result["redirectUrls"],
        "downloadLatency" => download_latency,
        "hasSchemaOrg" => result["hasSchemaOrg"],
        "schemaOrgId" => result["schemaOrgId"],
        "dcIdentifier" => result["dcIdentifier"],
        "citationDoi" => result["citationDoi"],
        "bodyHasPid" => result["bodyHasPid"],
      }

      doi.update_columns("landing_page": landing_page)

      Rails.logger.info "Updated " + doi.doi
    rescue TypeError, NoMethodError => e
      Rails.logger.error "Error updating landing page " + doi.doi + ": " + e.message
    end

    "Finished migrating landing pages."
  end

  def self.add_index_type(options = {})
    return nil if options[:from_id].blank?

    from_id = options[:from_id].to_i
    until_id = (options[:until_id] || (from_id + 499)).to_i

    # get every id between from_id and until_id
    count = 0

    Rails.logger.info "[migration_index_types] adding type information for DOIs with IDs #{from_id} - #{until_id}."

    Doi.where(id: from_id..until_id).where("type" => nil).find_each(batch_size: 500) do |doi|
      agency = doi.agency

      type = if agency.blank? || agency.casecmp?("datacite")
        "DataciteDoi"
      elsif agency.casecmp?("crossref")
        "OtherDoi"
      elsif agency.casecmp?("kisti")
        "OtherDoi"
      elsif agency.casecmp?("medra")
        "OtherDoi"
      elsif agency.casecmp?("istic")
        "OtherDoi"
      elsif agency.casecmp?("jalc")
        "OtherDoi"
      elsif agency.casecmp?("airiti")
        "OtherDoi"
      elsif agency.casecmp?("cnki")
        "OtherDoi"
      elsif agency.casecmp?("op")
        "OtherDoi"
      else
        "DataciteDoi"
      end

      doi.update_columns("type" => type)

      count += 1
      Rails.logger.info "Updated #{doi.doi} (#{doi.id})"
    rescue StandardError => e
      Rails.logger.error "Error updating #{doi.doi} (#{doi.id}), #{e.message}"
    end

    "Finished updating dois, total #{count}"
  end

  # QUICK FIX UNTIL PROJECT IS A RESOURCE_TYPE_GENERAL IN THE SCHEMA
  def handle_resource_type(types)
    if types.present? && types["resourceType"] == "Project" && (types["resourceTypeGeneral"] == "Text" || types["resourceTypeGeneral"] == "Other")
      "Project"
    else
      types.to_h["resourceTypeGeneral"]
    end
  end

  private
    def update_publisher_from_hash
      symbolized_publisher_hash = publisher_before_type_cast.symbolize_keys
      if !symbolized_publisher_hash.values.all?(nil)
        self.publisher_obj = {
          name: symbolized_publisher_hash.fetch(:name, nil),
          lang: symbolized_publisher_hash.fetch(:lang, nil),
          schemeUri: symbolized_publisher_hash.fetch(:schemeUri, nil),
          publisherIdentifier: symbolized_publisher_hash.fetch(:publisherIdentifier, nil),
          publisherIdentifierScheme: symbolized_publisher_hash.fetch(:publisherIdentifierScheme, nil)
        }.compact
      else
        reset_publishers
      end
    end

    def update_publisher_from_string
      self.publisher_obj = { name: publisher_before_type_cast }
     end

    def reset_publishers
      self.publisher_obj = nil
    end
end
