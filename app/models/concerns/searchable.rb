module Searchable
  extend ActiveSupport::Concern
  extend ActiveModel::Naming
  include ActiveModel::Serialization

  module ClassMethods
    def all
      collect_data
    end

    def where(options = {})
      collect_data(options)
    end

    def collect_data(options = {})
      data = get_data(options)
      parse_data(data, options)
    end

    def get_data(options = {})
      query_url = get_query_url(options)
      Maremma.get(query_url, options)
    end

    def parse_items(items, options = {})
      Array(items).map do |item|
        parse_item(item, options)
      end
    end

    def parse_item(item, options = {})
      new(item, options)
    end

    def parse_include(klass, params)
      klass.new(params)
    end
  end
end
