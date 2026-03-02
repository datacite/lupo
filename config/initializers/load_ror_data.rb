# frozen_string_literal: true

FUNDER_TO_ROR = JSON.parse(File.read(Rails.root.join("app/resources/funder_to_ror.json"))).freeze
ROR_HIERARCHY = JSON.parse(File.read(Rails.root.join("app/resources/ror_hierarchy.json"))).freeze
ROR_TO_COUNTRIES = JSON.parse(File.read(Rails.root.join("app/resources/ror_to_countries.json"))).freeze
