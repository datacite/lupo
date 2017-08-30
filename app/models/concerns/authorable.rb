module Authorable
  extend ActiveSupport::Concern

  require "namae"

  included do
    IDENTIFIER_SCHEME_URIS = {
      "ORCID" => "https://orcid.org/"
    }

    # parse author string into CSL format
    # only assume personal name when using sort-order: "Turing, Alan"
    def get_one_author(author, options = {})
      return { "literal" => "" } if author.strip.blank?

      author = cleanup_author(author)
      names = Namae.parse(author)

      if names.blank? || is_personal_name?(author).blank?
        { "literal" => author }
      else
        name = names.first

        { "family" => name.family,
          "given" => name.given }.compact
      end
    end

    def cleanup_author(author)
      # detect pattern "Smith J.", but not "Smith, John K."
      author = author.gsub(/[[:space:]]([A-Z]\.)?(-?[A-Z]\.)$/, ', \1\2') unless author.include?(",")

      # titleize strings
      # remove non-standard space characters
      author.my_titleize
            .gsub(/[[:space:]]/, ' ')
    end

    def is_personal_name?(author)
      return true if author.include?(",")

      # lookup given name
      ::NameDetector.name_exists?(author.split.first)
    end

    # parse array of author strings into CSL format
    def get_authors(authors, options={})
      Array(authors).map { |author| get_one_author(author, options) }
    end

    # parse array of author hashes into CSL format
    def get_hashed_authors(authors)
      Array(authors).map { |author| get_one_hashed_author(author) }
    end

    def get_one_hashed_author(author)
      raw_name = author.fetch("creatorName", nil)

      author_hsh = get_one_author(raw_name)
      author_hsh["ORCID"] = get_name_identifiers(author).first
      author_hsh.compact
    end

    # parse nameIdentifier from DataCite
    def get_name_identifiers(author)
      name_identifiers = Array.wrap(author.fetch("nameIdentifier", nil)).reduce([]) do |sum, n|
        n = { "__content__" => n } if n.is_a?(String)

        # fetch scheme_uri, default to ORCID
        scheme = n.fetch("nameIdentifierScheme", nil)
        scheme_uri = n.fetch("schemeURI", nil) || IDENTIFIER_SCHEME_URIS.fetch(scheme, "https://orcid.org")
        scheme_uri = "https://orcid.org/" if validate_orcid_scheme(scheme_uri)
        scheme_uri << '/' unless scheme_uri.present? && scheme_uri.end_with?('/')

        identifier = n.fetch("__content__", nil)
        if scheme_uri == "https://orcid.org/"
          identifier = validate_orcid(identifier)
        else
          identifier = identifier.gsub(" ", "-")
        end

        if identifier.present? && scheme_uri.present?
          sum << scheme_uri + identifier
        else
          sum
        end
      end

      # return array of name identifiers, ORCID ID is first element if multiple
      name_identifiers.select { |n| n.start_with?("https://orcid.org") } +
      name_identifiers.reject { |n| n.start_with?("https://orcid.org") }
    end

  end
end
