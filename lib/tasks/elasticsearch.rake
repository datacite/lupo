# frozen_string_literal: true

require "elasticsearch/rails/tasks/import"

namespace :elasticsearch do
  desc "create all indexes"
  task create_all_indexes: :environment do
    fail "These tasks can only be used in the development enviroment" if Rails.env.production?

    Rake::Task["provider:create_index"].invoke
    Rake::Task["provider:create_alias"].invoke

    Rake::Task["client:create_index"].invoke
    Rake::Task["client:create_alias"].invoke

    Rake::Task["repository:create_index"].invoke
    Rake::Task["repository:create_alias"].invoke

    Rake::Task["prefix:create_index"].invoke
    Rake::Task["prefix:create_alias"].invoke

    Rake::Task["provider_prefix:create_index"].invoke
    Rake::Task["provider_prefix:create_alias"].invoke

    Rake::Task["client_prefix:create_index"].invoke
    Rake::Task["client_prefix:create_alias"].invoke

    Rake::Task["other_doi:create_index"].invoke
    Rake::Task["other_doi:create_alias"].invoke

    Rake::Task["datacite_doi:create_index"].invoke
    Rake::Task["datacite_doi:create_alias"].invoke

    Rake::Task["event:create_index"].invoke
    Rake::Task["event:create_alias"].invoke

    Rake::Task["activity:create_index"].invoke
    Rake::Task["activity:create_alias"].invoke

    Rake::Task["contact:create_index"].invoke
    Rake::Task["contact:create_alias"].invoke

    Rake::Task["enrichment:create_index"].invoke
    Rake::Task["enrichment:create_alias"].invoke
  end

  desc "Refresh active-index cache entries from live OpenSearch aliases. Safe in production."
  task refresh_active_index_caches: :environment do
    model_names =
      if ENV["MODELS"].present?
        ENV["MODELS"].split(",").map(&:strip).reject(&:empty?)
      else
        IndexAliasCoordination::INDEXED_MODELS
      end

    seen_aliases = {}
    model_names.each do |model_name|
      model = model_name.constantize
      alias_name = model.index_name
      next if seen_aliases[alias_name]

      seen_aliases[alias_name] = true
      cached_before = Rails.cache.read(model.active_index_cache_key)
      live_after = model.refresh_index_name_cache!
      puts "#{alias_name} #{cached_before.inspect} -> #{live_after.inspect}"
    end
  end

  desc "delete all indexes"
  task delete_all_indexes: :environment do
    fail "These tasks can only be used in the development enviroment" if Rails.env.production?

    Rake::Task["provider:delete_index"].invoke
    Rake::Task["client:delete_index"].invoke
    Rake::Task["repository:delete_index"].invoke
    Rake::Task["prefix:delete_index"].invoke
    Rake::Task["provider_prefix:delete_index"].invoke
    Rake::Task["client_prefix:delete_index"].invoke
    Rake::Task["other_doi:delete_index"].invoke
    Rake::Task["datacite_doi:delete_index"].invoke
    Rake::Task["doi:delete_index"].invoke
    Rake::Task["event:delete_index"].invoke
    Rake::Task["activity:delete_index"].invoke
    Rake::Task["contact:delete_index"].invoke
    Rake::Task["enrichment:delete_index"].invoke
  end
end
