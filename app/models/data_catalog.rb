# frozen_string_literal: true

class DataCatalog
  # Kept so GraphQL dataCatalog / dataCatalogs still resolve. The re3data
  # endpoint (https://api.datacite.org/re3data) is no longer active, so these
  # methods do not perform HTTP and return an empty result.
  include Modelable

  def self.find_by_id(*_args, **_kwargs)
    log_retired
    { data: [], errors: nil }
  end

  def self.query(*_args, **_kwargs)
    log_retired
    { data: [], meta: { "total" => 0 }, errors: nil }
  end

  def self.all(*_args, **_kwargs)
    log_retired
    []
  end

  def self.warm_re3_cache(*_args, **_kwargs)
    log_retired
    nil
  end

  def self.fetch_and_cache_all(*_args, **_kwargs)
    log_retired
    []
  end

  def self.log_retired
    return if defined?(@retired_logged) && @retired_logged

    @retired_logged = true
    Rails.logger.warn(
      "DataCatalog re3data lookups are disabled; https://api.datacite.org/re3data is no longer active",
    )
  end
  private_class_method :log_retired
end
