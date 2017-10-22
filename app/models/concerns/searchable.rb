module Searchable
  extend ActiveSupport::Concern
  extend ActiveModel::Naming
  include ActiveModel::Serialization

  module ClassMethods
    def all
      collect_data
    end

    def where(options={})
      collect_data(options)
    end

    def debug
      true
    end

    def collect_data(options = {})
      if ENV["LOG_LEVEL"] == "debug" && self.debug
        data = nil
        time = Benchmark.realtime do
          data = get_data(options)
        end
        Rails.logger.debug "Got #{self.name} data for #{options.inspect} in #{time*1000} milliseconds"
        time = Benchmark.realtime do
          data = parse_data(data, options)
        end
        Rails.logger.debug "Parsed #{self.name} data for #{options.inspect} in #{time*1000} milliseconds"
        data
      else
        data = get_data(options)
        parse_data(data, options)
      end
    end

    def get_data(options={})
      query_url = get_query_url(options)
      Maremma.get(query_url, options)
    end

    def get_data(options={})
      query_url = get_query_url(options)
      Maremma.get(query_url, options)
    end

    def parse_items(items, options={})
      Array(items).map do |item|
        parse_item(item, options)
      end
    end

    def parse_item(item, options={})
      self.new(item, options)
    end

    def parse_include(klass, params)
      klass.new(params)
    end
  end
end
