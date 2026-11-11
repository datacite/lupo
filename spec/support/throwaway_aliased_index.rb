# frozen_string_literal: true

module ThrowawayAliasedIndex
  def opensearch_client
    Elasticsearch::Model.client
  end

  def throwaway_base
    "lupo-spec-#{SecureRandom.hex(8)}"
  end

  def create_throwaway_pair(base, active: :v1)
    v1 = "#{base}_v1"
    v2 = "#{base}_v2"
    [v1, v2].each do |index|
      if opensearch_client.indices.exists(index: index)
        opensearch_client.indices.delete(index: index)
      end
      opensearch_client.indices.create(
        index: index,
        body: { settings: { number_of_shards: 1, number_of_replicas: 0 } },
      )
    end
    holder = active == :v2 ? v2 : v1
    opensearch_client.indices.update_aliases(
      body: {
        actions: [
          { add: { index: holder, alias: base, is_write_index: true } },
        ],
      },
    )
    [v1, v2]
  end

  def delete_throwaway(*indexes)
    indexes.flatten.each do |index|
      next if index.blank?
      if opensearch_client.indices.exists(index: index)
        opensearch_client.indices.delete(index: index)
      end
    rescue Elastic::Transport::Transport::Error
      nil
    end
  end

  def refresh_interval_of(index)
    settings = opensearch_client.indices.get_settings(index: index)
    body = settings.respond_to?(:to_h) ? settings.to_h : settings
    body.dig(index, "settings", "index", "refresh_interval")
  end
end
