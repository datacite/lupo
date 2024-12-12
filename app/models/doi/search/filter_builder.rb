# frozen_string_literal: true

class Doi
  module Search
    class FilterBuilder
      include Modelable

      def initialize(options)
        @options = options
      end

      def build
        options = @options

        # turn ids into an array if provided as comma-separated string
        options[:ids] = options[:ids].split(",") if options[:ids].is_a?(String)

        filter = []
        filter << { terms: { doi: options[:ids].map(&:upcase) } } if options[:ids].present?
        filter << { terms: { uid: [options[:uid]] } } if options[:uid].present?
        filter << { terms: { resource_type_id: [options[:resource_type_id].underscore.dasherize] } } if options[:resource_type_id].present?
        filter << { terms: { "types.resourceType": options[:resource_type].split(",") } } if options[:resource_type].present?
        filter << { terms: { agency: options[:agency].split(",").map(&:downcase) } } if options[:agency].present?
        filter << { terms: { prefix: options[:prefix].to_s.split(",") } } if options[:prefix].present?
        filter << { terms: { language: options[:language].to_s.split(",").map(&:downcase) } } if options[:language].present?
        filter << { range: { created: { gte: "#{options[:created].split(',').min}||/y", lte: "#{options[:created].split(',').max}||/y", format: "yyyy" } } } if options[:created].present?
        filter << { range: { publication_year: { gte: "#{options[:published].split(',').min}||/y", lte: "#{options[:published].split(',').max}||/y", format: "yyyy" } } } if options[:published].present?
        filter << { terms: { schema_version: ["http://datacite.org/schema/kernel-#{options[:schema_version]}"] } } if options[:schema_version].present?
        filter << { terms: { "subjects.subject": options[:subject].split(",") } } if options[:subject].present?
        filter << { terms: { "rights_list.rightsIdentifier" => options[:license].split(",") } } if options[:license].present?
        filter << { terms: { source: [options[:source]] } } if options[:source].present?
        filter << { range: { reference_count: { "gte": options[:has_references].to_i } } } if options[:has_references].present?
        filter << { range: { citation_count: { "gte": options[:has_citations].to_i } } } if options[:has_citations].present?
        filter << { range: { part_count: { "gte": options[:has_parts].to_i } } } if options[:has_parts].present?
        filter << { range: { part_of_count: { "gte": options[:has_part_of].to_i } } } if options[:has_part_of].present?
        filter << { range: { version_count: { "gte": options[:has_versions].to_i } } } if options[:has_versions].present?
        filter << { range: { version_of_count: { "gte": options[:has_version_of].to_i } } } if options[:has_version_of].present?
        filter << { range: { view_count: { "gte": options[:has_views].to_i } } } if options[:has_views].present?
        filter << { range: { download_count: { "gte": options[:has_downloads].to_i } } } if options[:has_downloads].present?
        filter << { terms: { "landing_page.status": [options[:link_check_status]] } } if options[:link_check_status].present?
        filter << { exists: { field: "landing_page.checked" } } if options[:link_checked].present?
        filter << { terms: { "landing_page.hasSchemaOrg": [options[:link_check_has_schema_org]] } } if options[:link_check_has_schema_org].present?
        filter << { terms: { "landing_page.bodyHasPid": [options[:link_check_body_has_pid]] } } if options[:link_check_body_has_pid].present?
        filter << { exists: { field: "landing_page.schemaOrgId" } } if options[:link_check_found_schema_org_id].present?
        filter << { exists: { field: "landing_page.dcIdentifier" } } if options[:link_check_found_dc_identifier].present?
        filter << { exists: { field: "landing_page.citationDoi" } } if options[:link_check_found_citation_doi].present?
        filter << { range: { "landing_page.redirectCount": { "gte": options[:link_check_redirect_count_gte] } } } if options[:link_check_redirect_count_gte].present?
        filter << { terms: { aasm_state: options[:state].to_s.split(",") } } if options[:state].present?
        filter << { range: { registered: { gte: "#{options[:registered].split(',').min}||/y", lte: "#{options[:registered].split(',').max}||/y", format: "yyyy" } } } if options[:registered].present?
        filter << { terms: { consortium_id: [options[:consortium_id].downcase] } } if options[:consortium_id].present?
        filter << { terms: { "client.re3data_id": [doi_from_url(options[:re3data_id])] } } if options[:re3data_id].present? # TODO align PID parsing
        filter << { terms: { "client.opendoar_id": [options[:opendoar_id]] } } if options[:opendoar_id].present?
        filter << { terms: { "client.certificate" => options[:certificate].split(",") } } if options[:certificate].present?
        filter << { terms: { "creators.nameIdentifiers.nameIdentifier" => options[:user_id].split(",").collect { |id| "https://orcid.org/#{orcid_from_url(id)}" } } } if options[:user_id].present?
        filter << { terms: { "creators.nameIdentifiers.nameIdentifierScheme": ["ORCID"] } } if options[:has_person].present?
        filter << { terms: { "client.client_type": [options[:client_type]] } } if options[:client_type]
        filter << { terms: { "types.resourceTypeGeneral": ["PhysicalObject"] } } if options[:client_type] == "igsnCatalog"
        filter.push(*build_pid_entity_filter) if options[:pid_entity].present?
        filter.push(*build_field_of_science_filter) if options[:field_of_science].present?
        filter << build_field_of_science_repository_filter if options[:field_of_science_repository].present?
        filter << build_field_of_science_combined_filter if options[:field_of_science_combined].present?

        filter
      end

      private
        def build_pid_entity_filter
          [
            { terms: { "subjects.subjectScheme": ["PidEntity"] } },
            { terms: { "subjects.subject": @options[:pid_entity].split(",").map(&:humanize) } }
          ]
        end

        def build_field_of_science_filter
          [
            { terms: { "subjects.subjectScheme": ["Fields of Science and Technology (FOS)"] } },
            { terms: { "subjects.subject": @options[:field_of_science].split(",").map { |s| "FOS: " + s.humanize } } }
          ]
        end

        def build_field_of_science_repository_filter
          { terms: { "fields_of_science_repository": @options[:field_of_science_repository].split(",").map { |s| s.humanize } } }
        end

        def build_field_of_science_combined_filter
          { terms: { "fields_of_science_combined": @options[:field_of_science_combined].split(",").map { |s| s.humanize } } }
        end
    end
  end
end
