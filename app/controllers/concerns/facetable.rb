# frozen_string_literal: true

module Facetable
  extend ActiveSupport::Concern

  SOURCES = {
    "datacite-usage" => "DataCite Usage Stats",
    "datacite-resolution" => "DataCite Resolution Stats",
    "datacite-related" => "DataCite Related Identifiers",
    "datacite-crossref" => "DataCite to Crossref",
    "datacite-kisti" => "DataCite to KISTI",
    "datacite-cnki" => "DataCite to CNKI",
    "datacite-istic" => "DataCite to ISTIC",
    "datacite-medra" => "DataCite to mEDRA",
    "datacite-op" => "DataCite to OP",
    "datacite-jalc" => "DataCite to JaLC",
    "datacite-airiti" => "DataCite to Airiti",
    "datacite-url" => "DataCite URL Links",
    "datacite-funder" => "DataCite Funder Information",
    "crossref" => "Crossref to DataCite",
  }.freeze

  REGIONS = {
    "APAC" => "Asia and Pacific",
    "EMEA" => "Europe, Middle East and Africa",
    "AMER" => "Americas",
  }.freeze

  REGISTRATION_AGENCIES = {
    "airiti" => "Airiti",
    "cnki" => "CNKI",
    "crossref" => "Crossref",
    "datacite" => "DataCite",
    "istic" => "ISTIC",
    "jalc" => "JaLC",
    "kisti" => "KISTI",
    "medra" => "mEDRA",
    "op" => "OP",
  }.freeze

  LICENSES = {
    "afl-1.1" => "AFL-1.1",
    "apache-2.0" => "Apache-2.0",
    "bsd-2-clause" => "BSD-2-clause",
    "bsd-3-clause" => "BSD-3-clause",
    "cc-by-1.0" => "CC-BY-1.0",
    "cc-by-2.0" => "CC-BY-2.0",
    "cc-by-2.5" => "CC-BY-2.5",
    "cc-by-3.0" => "CC-BY-3.0",
    "cc-by-4.0" => "CC-BY-4.0",
    "cc-by-nc-2.0" => "CC-BY-NC-2.0",
    "cc-by-nc-2.5" => "CC-BY-NC-2.5",
    "cc-by-nc-3.0" => "CC-BY-NC-3.0",
    "cc-by-nc-4.0" => "CC-BY-NC-4.0",
    "cc-by-nc-nd-3.0" => "CC-BY-NC-ND-3.0",
    "cc-by-nc-nd-4.0" => "CC-BY-NC-ND-4.0",
    "cc-by-nc-sa-3.0" => "CC-BY-NC-SA-3.0",
    "cc-by-nc-sa-4.0" => "CC-BY-NC-SA-4.0",
    "cc-by-nd-2.0" => "CC-BY-ND-2.0",
    "cc-by-nd-3.0" => "CC-BY-ND-3.0",
    "cc-by-nd-4.0" => "CC-BY-ND-4.0",
    "cc-by-sa-4.0" => "CC-BY-SA-4.0",
    "cc-pddc" => "CC-PDDC",
    "cc0-1.0" => "CC0-1.0",
    "eupl-1.1" => "EUPL-1.1",
    "gpl-2.0+" => "GPL-2.0+",
    "gpl-3.0" => "GPL-3.0",
    "isc" => "ISC",
    "mit" => "MIT",
    "mpl-2.0" => "MPL-2.0",
    "ogl-canada-2.0" => "OGL-Canada-2.0",
    "__missing__" => "Missing",
  }.freeze

  LOWER_BOUND_YEAR = 2_010

  CLIENT_TYPES = {
    "repository" => "Repository",
    "periodical" => "Periodical",
    "igsnCatalog" => "IGSN ID Catalog",
    "raidRegistry" => "RAiD Registry",
  }.freeze

  OTHER = { "__other__" => "Other", "__missing__" => "Missing" }.freeze

  included do
    def facet_by_key_as_string(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key_as_string"],
          "title" => hsh["key_as_string"],
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_year(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key_as_string"][0..3],
          "title" => hsh["key_as_string"][0..3],
          "count" => hsh["doc_count"],
        }
      end
    end

    # remove years in the future and only keep 12 most recent years
    def facet_by_range(arr)
      interval = Date.current.year - LOWER_BOUND_YEAR

      arr.select { |a| a["key_as_string"].to_i <= Date.current.year }[
        0..interval
      ].
        map do |hsh|
        {
          "id" => hsh["key_as_string"],
          "title" => hsh["key_as_string"],
          "count" => hsh["doc_count"],
        }
      end
    end

    def metric_facet_by_year(arr)
      arr.reduce([]) do |sum, hsh|
        if hsh.dig("metric_count", "value").to_i > 0
          sum <<
            {
              "id" => hsh["key_as_string"][0..3],
              "title" => hsh["key_as_string"][0..3],
              "count" => hsh.dig("metric_count", "value").to_i,
            }
        end

        sum
      end
    end

    def facet_by_registration_agency(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key"],
          "title" => REGISTRATION_AGENCIES[hsh["key"]] || hsh["key"],
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_language(arr)
      arr.map do |hsh|
        la = ISO_639.find_by_code(hsh["key"])
        {
          "id" => hsh["key"],
          "title" =>
            la.present? ? la.english_name.split(/\W+/).first : hsh["key"],
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_annual(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key"][0..3],
          "title" => hsh["key"][0..3],
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_date(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key"][0..9],
          "title" => hsh["key"][0..9],
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_cumulative_year(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key"].to_s,
          "title" => hsh["key"].to_s,
          "count" => hsh["doc_count"],
        }
      end
    end


    def facet_by_key(arr, title_case: true)
      arr.map do |hsh|
        title = title_case ? hsh["key"].titleize : hsh["key"]
        {
          "id" => hsh["key"],
          "title" => title,
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_bool(arr)
      arr.map do |hsh|
        id = hsh["key"] == 1 ? "true" : "false"

        {
          "id" => id,
          "title" => id.capitalize,
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_client_type(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key"],
          "title" => CLIENT_TYPES[hsh["key"]] || hsh["key"],
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_software(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key"].parameterize(separator: "_"),
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_license(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key"],
          "title" => LICENSES[hsh["key"]] || hsh["key"],
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_schema(arr)
      arr.map do |hsh|
        id = hsh["key"].split("-").last

        { "id" => id, "title" => "Schema #{id}", "count" => hsh["doc_count"] }
      end
    end

    def facet_by_region(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key"].downcase,
          "title" => REGIONS[hsh["key"]] || hsh["key"],
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_resource_type(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key"].underscore.dasherize,
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_source(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key"],
          "title" => SOURCES[hsh["key"]] || hsh["key"],
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_relation_type(arr)
      arr.map do |hsh|
        year_month_arr =
          hsh.dig("year_month", "buckets").map do |h|
            {
              "id" => h["key_as_string"],
              "title" => h["key_as_string"],
              "sum" => h["doc_count"],
            }
          end

        {
          "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "yearMonths" => year_month_arr,
        }
      end
    end

    def facet_by_relation_type_v1(arr)
      arr.map do |hsh|
        year_month_arr =
          hsh.dig("year_month", "buckets").map do |h|
            {
              "id" => h["key_as_string"],
              "title" => h["key_as_string"],
              "sum" => h["doc_count"],
            }
          end

        {
          "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "year-months" => year_month_arr,
        }
      end
    end

    def facet_by_citation_type(arr)
      arr.map do |hsh|
        year_month_arr =
          hsh.dig("year_month", "buckets").map do |h|
            {
              "id" => h["key_as_string"],
              "title" => h["key_as_string"],
              "sum" => h["doc_count"],
            }
          end

        {
          "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "yearMonths" => year_month_arr,
        }
      end
    end

    def facet_by_citation_type_v1(arr)
      arr.map do |hsh|
        year_month_arr =
          hsh.dig("year_month", "buckets").map do |h|
            {
              "id" => h["key_as_string"],
              "title" => h["key_as_string"],
              "sum" => h["doc_count"],
            }
          end

        {
          "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "year-months" => year_month_arr,
        }
      end
    end

    def facet_by_registrants(arr)
      arr.map do |hsh|
        year_arr =
          hsh.dig("year", "buckets").map do |h|
            {
              "id" => h["key_as_string"],
              "title" => h["key_as_string"],
              "sum" => h["doc_count"],
            }
          end

        {
          "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "years" => year_arr,
        }
      end
    end

    def providers_totals(arr)
      providers =
        Provider.unscoped.where(
          "allocator.role_name IN ('ROLE_FOR_PROFIT_PROVIDER', 'ROLE_CONTRACTUAL_PROVIDER', 'ROLE_CONSORTIUM' , 'ROLE_CONSORTIUM_ORGANIZATION', 'ROLE_ALLOCATOR')",
        ).
          where(deleted_at: nil).
          pluck(:symbol, :name).
          to_h

      arr.reduce([]) do |sum, hsh|
        if providers[hsh["key"].upcase]
          sum <<
            {
              "id" => hsh["key"],
              "title" => providers[hsh["key"].upcase],
              "count" => hsh["doc_count"],
              "temporal" => {
                "this_month" => facet_annual(hsh.this_month.buckets),
                "this_year" => facet_annual(hsh.this_year.buckets),
                "last_year" => facet_annual(hsh.last_year.buckets),
                "two_years_ago" => facet_annual(hsh.two_years_ago.buckets),
              },
              "states" => facet_by_key(hsh.states.buckets),
            }
        end

        sum
      end
    end

    def prefixes_totals(arr)
      arr.map do |hsh|
        {
          "id" => hsh["key"],
          "title" => hsh["key"],
          "count" => hsh["doc_count"],
          "temporal" => {
            "this_month" => facet_annual(hsh.this_month.buckets),
            "this_year" => facet_annual(hsh.this_year.buckets),
            "last_year" => facet_annual(hsh.last_year.buckets),
          },
          "states" => facet_by_key(hsh.states.buckets),
        }
      end
    end

    def clients_totals(arr)
      clients = Client.all.pluck(:symbol, :name).to_h

      arr.map do |hsh|
        {
          "id" => hsh["key"],
          "title" => clients[hsh["key"].upcase],
          "count" => hsh["doc_count"],
          "temporal" => {
            "this_month" => facet_annual(hsh.this_month.buckets),
            "this_year" => facet_annual(hsh.this_year.buckets),
            "last_year" => facet_annual(hsh.last_year.buckets),
            "two_years_ago" => facet_annual(hsh.two_years_ago.buckets),
          },
          "states" => facet_by_key(hsh.states.buckets),
        }
      end
    end

    def facet_by_combined_key(arr)
      arr.map do |hsh|
        id, title = hsh["key"].split(":", 2)
        if id == "__missing__"
          title = OTHER["__missing__"]
        end
        { "id" => id, "title" => title, "count" => hsh["doc_count"] }
      end
    end

    def facet_by_fos(arr)
      arr.map do |hsh|
        title = hsh["key"].gsub("FOS: ", "")
        {
          "id" => title.parameterize(separator: "_"),
          "title" => title,
          "count" => hsh["doc_count"],
        }
      end
    end

    def facet_by_funders(arr)
      arr.map { |hsh|
        funder_id = hsh["key"]

        if funder_id.nil?
          next
        end

        # The aggregation query should only return 1 hit, so hence the index
        # into first element
        all_funders = hsh.dig("funders", "hits", "hits")[0].dig("_source", "funding_references")

        # Filter through funders to find the funder that matches the key
        matched_funder = all_funders.find do |funder|
          funder.fetch("funderIdentifier", nil) == funder_id
        end

        if matched_funder
          title = matched_funder.fetch("funderName", funder_id)
          {
            "id" => funder_id,
            "title" => title,
            "count" => hsh["doc_count"],
          }
        end
      }.compact
    end

    def _facet_by_general_contributor(arr, aggregate, source)
      arr.map { |hsh|
        orcid_id = %r{\A(?:(http|https)://(orcid.org)/)(.+)\z}.match?(hsh["key"]) && hsh["key"]

        if orcid_id.nil?
          next
        end

        # The aggregation query should only return 1 hit, so hence the index
        # into first element
        creators = hsh.dig(aggregate, "hits", "hits")[0].dig("_source", source)

        # Filter through creators to find creator that matches the key
        matched_creator = creators.select do |creator|
          if creator.key?("nameIdentifiers")
            Array.wrap(creator["nameIdentifiers"]).any? { |ni| ni["nameIdentifier"] == orcid_id }
          end
        end

        if matched_creator.any?
          title = matched_creator[0]["name"]

          {
            "id" => orcid_id,
            "title" => title,
            "count" => hsh["doc_count"],
          }
        end
      }.compact
    end

    def facet_by_authors(arr)
      _facet_by_general_contributor(arr, "authors", "creators")
    end

    def facet_by_creators_and_contributors(arr)
      _facet_by_general_contributor(arr, "creators_and_contributors", "creators_and_contributors")
    end

    def multi_facet_by_contributors_and_worktype(arr)
      outer = _facet_by_general_contributor(arr, "creators_and_contributors", "creators_and_contributors")
      outer.map do |hsh|
        creator_hash = arr.find { |h| h["key"] == hsh["id"] }
        inner = facet_by_combined_key(creator_hash.dig("work_types", "buckets"))
        hsh.merge("inner" => inner)
      end
    end

    def add_other(arr, other_count)
      if other_count > 0
        arr << {
          "id" => "__other__",
          "title" => OTHER["__other__"],
          "count" => other_count,
        }
      end

      arr
    end

    def add_other(arr, other_count)
      if other_count > 0
        arr << {
          "id" => "__other__",
          "title" => OTHER["__other__"],
          "count" => other_count,
        }
      end

      arr
    end
  end
end
