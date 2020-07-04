# frozen_string_literal: true

class BaseConnection < GraphQL::Types::Relay::BaseConnection
  REGIONS = {
    "APAC" => "Asia and Pacific",
    "EMEA" => "Europe, Middle East and Africa",
    "AMER" => "Americas"
  }

  REGISTRATION_AGENCIES = {
    "airiti" =>   "Airiti",
    "cnki" =>     "CNKI",
    "crossref" => "Crossref",
    "datacite" => "DataCite",
    "istic" =>    "ISTIC",
    "jalc" =>     "JaLC",
    "kisti" =>    "KISTI",
    "medra" =>    "mEDRA",
    "op" =>       "OP"
  }

  LICENSES = {
    "afl-1.1"         => "AFL-1.1",
    "apache-2.0"      => "Apache-2.0",
    "cc-by-1.0"       => "CC-BY-1.0",
    "cc-by-2.0"       => "CC-BY-2.0",
    "cc-by-2.5"       => "CC-BY-2.5",
    "cc-by-3.0"       => "CC-BY-3.0",
    "cc-by-4.0"       => "CC-BY-4.0",
    "cc-by-nc-4.0"    => "CC-BY-NC-4.0",
    "cc-by-nc-nd-4.0" => "CC-BY-NC-ND-4.0",
    "cc-by-nc-sa-4.0" => "CC-BY-NC-SA-4.0",
    "cc-pddc"         => "CC-PDDC",
    "cc0-1.0"         => "CC0-1.0",
    "gpl-3.0"         => "GPL-3.0",
    "isc"             => "ISC",
    "mit"             => "MIT",
    "mpl-2.0"         => "MPL-2.0",
    "ogl-canada-2.0"  => "OGL-Canada-2.0"
  }

  # direct ISO639-1 mapping should be faster and avoids verbose labels
  # for es, nl, el
  LANGUAGES = {
    "de" => "German",
    "el" => "Greek",
    "en" => "English",
    "es" => "Spanish",
    "fr" => "French",
    "it" => "Italian",
    "la" => "Latin",
    "nl" => "Dutch",
    "ru" => "Russian"
  }
  
  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match?(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, "").downcase
    end
  end

  def orcid_from_url(url)
    if /\A(?:(http|https):\/\/(orcid.org)\/)(.+)\z/.match?(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, "").downcase
    end
  end

  def facet_by_year(arr)
    arr.map do |hsh|
      { "id" => hsh["key_as_string"][0..3],
        "title" => hsh["key_as_string"][0..3],
        "count" => hsh["doc_count"] }
    end
  end

  def facet_by_key(arr)
    arr.map do |hsh|
      { "id" => hsh["key"],
        "title" => hsh["key"].titleize,
        "count" => hsh["doc_count"] }
    end
  end

  def facet_by_resource_type(arr)
    arr.map do |hsh|
      { "id" => hsh["key"].underscore.dasherize,
        "title" => hsh["key"],
        "count" => hsh["doc_count"] }
    end
  end

  def facet_by_software(arr)
    arr.map do |hsh|
      { "id" => hsh["key"].parameterize(separator: '_'),
        "title" => hsh["key"],
        "count" => hsh["doc_count"] }
    end
  end

  def facet_by_license(arr)
    arr.map do |hsh|
      { "id" => hsh["key"],
        "title" => LICENSES[hsh["key"]] || hsh["key"],
        "count" => hsh["doc_count"] }
    end
  end

  def facet_by_combined_key(arr)
    arr.map do |hsh|
      id, title = hsh["key"].split(":", 2)

      { "id" => id,
        "title" => title,
        "count" => hsh["doc_count"] }
    end
  end

  def facet_by_region(arr)
    arr.map do |hsh|
      { "id" => hsh["key"].downcase,
        "title" => REGIONS[hsh["key"]] || hsh["key"],
        "count" => hsh["doc_count"] }
    end
  end

  def facet_by_fos(arr)
    arr.map do |hsh|
      title = hsh["key"].gsub("FOS: ", "")
      { "id" => title.parameterize(separator: '_'),
        "title" => title,
        "count" => hsh["doc_count"] }
    end
  end

  def facet_by_registration_agency(arr)
    arr.map do |hsh|
      { "id" => hsh["key"],
        "title" => REGISTRATION_AGENCIES[hsh["key"]] || hsh["key"],
        "count" => hsh["doc_count"] }
    end
  end

  # remove years in the future and only keep 10 most recent years
  def facet_by_range(arr)
    arr.select { |a| a["key_as_string"].to_i <= 2020 }[0..9].map do |hsh|
      { "id" => hsh["key_as_string"],
        "title" => hsh["key_as_string"],
        "count" => hsh["doc_count"] }
    end
  end

  def facet_by_language(arr)
    arr.map do |hsh|
      { "id" => hsh["key"],
        "title" => LANGUAGES[hsh["key"]] || hsh["key"],
        "count" => hsh["doc_count"] }
    end
  end
end
