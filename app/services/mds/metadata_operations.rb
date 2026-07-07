# frozen_string_literal: true

module Mds
  # In-process metadata operations for classic MDS /metadata surface.
  class MetadataOperations
    include Bolognese::DoiUtils
    include Bolognese::Utils
    include Helpable

    UPPER_LIMIT = 1_073_741_823

    attr_reader :current_user, :current_ability

    def initialize(current_user:)
      @current_user = current_user
      @current_ability = Ability.new(current_user)
    end

    def get(doi_string)
      doi_id = validate_doi(doi_string)
      return Result.error(404, "DOI is unknown to MDS") if doi_id.blank?

      doi = DataciteDoi.where(doi: doi_id).first
      return Result.error(404, "DOI is unknown to MDS") if doi.blank?

      unless current_ability.can?(:read, doi)
        return Result.error(403, "Access is denied")
      end

      xml = doi.xml
      return Result.error(204, nil) if xml.blank?

      Result.ok(xml, status: 200)
    end

    def create(doi_string: nil, data:, number: nil)
      from = data.blank? ? "datacite" : find_from_format_by_string(data)
      return Result.error(415, "Metadata format not recognized") if from.blank?

      doi_id = extract_doi(doi_string, data: data, from: from, number: number)
      return Result.error(404, "DOI not found") if doi_id.blank?

      xml_b64 = data.present? ? Base64.strict_encode64(data) : nil
      raw_attrs = {
        doi: doi_id,
        xml: xml_b64,
        should_validate: true,
        source: "mds",
        event: "show",
        client_id: client_symbol,
      }.compact

      attrs = ParamsSanitizer.new(raw_attrs).cleanse

      doi = DataciteDoi.where(doi: doi_id).first
      exists = doi.present?

      if exists
        unless current_ability.can?(:update, doi)
          return Result.error(403, "Access is denied")
        end

        doi.current_user = current_user
        doi.assign_attributes(attrs.except(:doi, :client_id))
      else
        doi = DataciteDoi.new(attrs.merge(doi: doi_id))
        doi.current_user = current_user
        unless current_ability.can?(:new, doi)
          return Result.error(403, "Access is denied")
        end
      end

      if doi.save
        minted = doi.doi.to_s.upcase
        Result.created(
          "OK (#{minted})",
          headers: { "Location" => "#{Mds.url}/metadata/#{doi.doi}" },
        )
      else
        message = doi.errors.full_messages.first || "Unprocessable entity"
        Result.error(422, message)
      end
    rescue ActiveRecord::RecordNotFound
      Result.error(404, "DOI not found")
    end

    def destroy(doi_string)
      doi_id = validate_doi(doi_string)
      return Result.error(404, "DOI is unknown to MDS") if doi_id.blank?

      doi = DataciteDoi.where(doi: doi_id).first
      return Result.error(404, "DOI is unknown to MDS") if doi.blank?

      unless current_ability.can?(:update, doi)
        return Result.error(403, "Access is denied")
      end

      doi.current_user = current_user
      doi.assign_attributes(event: "hide")

      if doi.save(validate: false)
        Result.ok("OK")
      else
        message = doi.errors.full_messages.first || "Unprocessable entity"
        Result.error(422, message)
      end
    end

    def find_from_format_by_string(string)
      if Maremma.from_xml(string).to_h.dig("doi_records", "doi_record", "crossref").present?
        "crossref"
      elsif Nokogiri::XML(string, nil, "UTF-8", &:noblanks).collect_namespaces.detect { |_, v| v.to_s.start_with?("http://datacite.org/schema/kernel") }
        "datacite"
      elsif Maremma.from_json(string).to_h.dig("@context").to_s.start_with?("http://schema.org", "https://schema.org")
        "schema_org"
      elsif Maremma.from_json(string).to_h.dig("@context") == "https://raw.githubusercontent.com/codemeta/codemeta/master/codemeta.jsonld"
        "codemeta"
      elsif Maremma.from_json(string).to_h.dig("schema-version").to_s.start_with?("http://datacite.org/schema/kernel")
        "datacite_json"
      elsif Maremma.from_json(string).to_h.dig("types").present?
        "crosscite"
      elsif Maremma.from_json(string).to_h.dig("issued", "date-parts").present?
        "citeproc"
      elsif string.start_with?("TY  - ")
        "ris"
      elsif begin
        BibTeX.parse(string).first
      rescue StandardError
        nil
      end
        "bibtex"
      end
    rescue StandardError
      nil
    end

    def extract_doi(str, options = {})
      doi = validate_doi(str)
      return doi if doi.present?

      if options[:from] == "datacite"
        doi = doi_from_xml(str, options)
        return doi if doi.present?
      end

      generate_unique_doi(str, options)
    end

    private

    def client_symbol
      (current_user.client_id.presence || current_user.uid).to_s
    end

    def doi_from_xml(str, options = {})
      doc = Nokogiri::XML(str || options[:data], nil, "UTF-8", &:noblanks)
      doc.remove_namespaces!
      identifier = doc.at_css("identifier")
      identifier = identifier.content if identifier.present?
      validate_doi(identifier)
    end

    def generate_unique_doi(str, options = {})
      if options[:number].present?
        doi = generate_random_dois(str, number: options[:number]).first
        existing = DataciteDoi.where(doi: doi).exists?
        fail IdentifierError, "doi:#{doi} has already been registered" if existing
      else
        doi = nil
        duplicate = true
        while duplicate
          doi = generate_random_dois(str, options).first
          duplicate = !Rails.env.test? && DataciteDoi.where(doi: doi).exists?
        end
      end

      doi
    end
  end
end
