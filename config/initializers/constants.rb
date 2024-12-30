# frozen_string_literal: true

class IdentifierError < RuntimeError; end

RESCUABLE_EXCEPTIONS = [
  CanCan::AccessDenied,
  CanCan::AuthorizationNotPerformed,
  ActiveModelSerializers::Adapter::JsonApi::Deserialization::InvalidDocument,
  JWT::DecodeError,
  JWT::VerificationError,
  JSON::ParserError,
  Nokogiri::XML::SyntaxError,
  NoMethodError,
  SocketError,
  ActionDispatch::Http::Parameters::ParseError,
  ActiveRecord::RecordNotUnique,
  ActiveRecord::RecordNotFound,
  AbstractController::ActionNotFound,
  ActionController::BadRequest,
  ActionController::UnknownFormat,
  ActionController::RoutingError,
  ActionController::ParameterMissing,
  ActionController::UnpermittedParameters,
].freeze

# Format used for DOI validation
# The prefix is 10.x where x is 4-5 digits. The suffix can be anything, but can"t be left off
DOI_FORMAT = %r{\A10\.\d{4,5}/.+}

# Format used for URL validation
URL_FORMAT = %r{\A(http|https|ftp)://[a-z0-9]+([\-.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?/.*)?\z}

# Form queue options
QUEUE_OPTIONS = %w[high default low].freeze

# Version of ORCID API
ORCID_VERSION = "1.2"

# ORCID schema
ORCID_SCHEMA =
  "https://raw.githubusercontent.com/ORCID/ORCID-Source/master/orcid-model/src/main/resources/orcid-message-1.2.xsd"

# Version of DataCite API
DATACITE_VERSION = "4"

# Date of DataCite Schema
DATACITE_SCHEMA_DATE = "2016-09-21"

# regions used by countries gem
REGIONS = {
  "APAC" => "Asia and Pacific",
  "EMEA" => "Europe, Middle East and Africa",
  "AMER" => "Americas",
}.freeze

RESOURCE_TYPES_GENERAL = {
  "Audiovisual" => "Audiovisual",
  "Award" => "Award",
  "Book" => "Book",
  "BookChapter" => "Book Chapter",
  "Collection" => "Collection",
  "ComputationalNotebook" => "Computational Notebook",
  "ConferencePaper" => "Conference Paper",
  "ConferenceProceeding" => "Conference Proceeding",
  "Dataset" => "Dataset",
  "DataPaper" => "Data Paper",
  "Dissertation" => "Dissertation",
  "Event" => "Event",
  "Image" => "Image",
  "Instrument" => "Instrument",
  "InteractiveResource" => "Interactive Resource",
  "Journal" => "Journal",
  "JournalArticle" => "Journal Article",
  "Model" => "Model",
  "OutputManagementPlan" => "Output Management Plan",
  "PeerReview" => "Peer Review",
  "PhysicalObject" => "Physical Object",
  "Preprint" => "Preprint",
  "Project" => "Project",
  "Report" => "Report",
  "Service" => "Service",
  "Sound" => "Sound",
  "Software" => "Software",
  "Standard" => "Standard",
  "StudyRegistration" => "Study Registration",
  "Text" => "Text",
  "Workflow" => "Workflow",
  "Other" => "Other",
}.freeze

LAST_SCHEMA_VERSION = "http://datacite.org/schema/kernel-4"

METADATA_FORMATS = %w[schema_org ris bibtex citeproc crossref codemeta].freeze
