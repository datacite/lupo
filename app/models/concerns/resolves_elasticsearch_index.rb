# frozen_string_literal: true

# Resolves :active / :inactive index tokens to concrete OpenSearch index names
# (via the model's cached active_index / inactive_index helpers).
module ResolvesElasticsearchIndex
  extend ActiveSupport::Concern

  INDEX_ALIAS_TOKENS = [:active, :inactive, "active", "inactive"].freeze

  class_methods do
    def resolve_index_option(model, index)
      case index
      when :active, "active"
        model.active_index
      when :inactive, "inactive"
        model.inactive_index
      else
        index
      end
    end

    def index_alias_token?(index)
      INDEX_ALIAS_TOKENS.include?(index)
    end
  end

  private

  # Returns options with a concrete :index, or nil when a token could not be resolved
  # (caller should skip the import).
  def resolve_options_index(model, options)
    opts = options.deep_dup
    return opts unless opts.key?(:index) || opts.key?("index")

    raw = opts[:index]
    raw = opts["index"] if raw.nil?
    resolved = self.class.resolve_index_option(model, raw)

    if self.class.index_alias_token?(raw) && resolved.blank?
      Rails.logger.error(
        "[Elasticsearch] Could not resolve index token #{raw.inspect} for #{model.name}",
      )
      return nil
    end

    opts[:index] = resolved
    opts
  end
end
