module Indexable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    if Rails.env.development? || Rails.env.stage?
      after_save { IndexerJob.perform_later(self, operation: "index") }
      after_destroy { IndexerJob.perform_later(self, operation: "delete") }
    end
  end

  module ClassMethods
    # Elasticsearch custom search
    def query query, options={}
      __elasticsearch__.search(
        {
          query: {
            query_string: {
              query: query,
              fields: self.new.es_fields
            }
          }
        }
      ).records
    end

  #   def query query, options={}
  #
  #     # Prefill and set the filters (top-level `post_filter` and aggregation `filter` elements)
  #     #
  #     __set_filters = lambda do |key, f|
  #       @search_definition[:post_filter][:bool] ||= {}
  #       @search_definition[:post_filter][:bool][:must] ||= []
  #       @search_definition[:post_filter][:bool][:must]  |= [f]
  #
  #       @search_definition[:aggregations][key.to_sym][:filter][:bool][:must] ||= []
  #       @search_definition[:aggregations][key.to_sym][:filter][:bool][:must]  |= [f]
  #     end
  #
  #     @search_definition = {
  #       query: {},
  #
  #       # highlight: {
  #       #   pre_tags: ['<em class="label label-highlight">'],
  #       #   post_tags: ['</em>'],
  #       #   fields: {
  #       #     title:    { number_of_fragments: 0 },
  #       #     abstract: { number_of_fragments: 0 },
  #       #     content:  { fragment_size: 50 }
  #       #   }
  #       # },
  #
  #       post_filter: {},
  #
  #       aggregations: {
  #         categories: {
  #           filter: { bool: { must: [ match_all: {} ] } },
  #           aggregations: { categories: { terms: { field: 'categories' } } }
  #         },
  #         authors: {
  #           filter: { bool: { must: [ match_all: {} ] } },
  #           aggregations: { authors: { terms: { field: 'authors.full_name.raw' } } }
  #         },
  #         published: {
  #           filter: { bool: { must: [ match_all: {} ] } },
  #           aggregations: {
  #             published: { date_histogram: { field: 'published_on', interval: 'week' } }
  #           }
  #         }
  #       }
  #     }
  #
  #     unless query.blank?
  #       @search_definition[:query] = {
  #         bool: {
  #           should: [
  #             { multi_match: {
  #                 query: query,
  #                 fields: self.new.es_fields,
  #                 operator: 'and'
  #               }
  #             }
  #           ]
  #         }
  #       }
  #     else
  #       @search_definition[:query] = { match_all: {} }
  #       @search_definition[:sort]  = { published_on: 'desc' }
  #     end
  #
  #     # if options[:client_id]
  #     #   f = { term: { client_id: options[:client_id] } }
  #     #
  #     #   __set_filters.(:authors, f)
  #     #   __set_filters.(:published, f)
  #     # end
  #     #
  #     # if options[:author]
  #     #   f = { term: { 'authors.full_name.raw' => options[:author] } }
  #     #
  #     #   __set_filters.(:categories, f)
  #     #   __set_filters.(:published, f)
  #     # end
  #     #
  #     # if options[:published_week]
  #     #   f = {
  #     #     range: {
  #     #       published_on: {
  #     #         gte: options[:published_week],
  #     #         lte: "#{options[:published_week]}||+1w"
  #     #       }
  #     #     }
  #     #   }
  #     #
  #     #   __set_filters.(:categories, f)
  #     #   __set_filters.(:authors, f)
  #     # end
  #
  #     # if query.present? && options[:comments]
  #     #   @search_definition[:query][:bool][:should] ||= []
  #     #   @search_definition[:query][:bool][:should] << {
  #     #     nested: {
  #     #       path: 'comments',
  #     #       query: {
  #     #         multi_match: {
  #     #           query: query,
  #     #           fields: ['comments.body'],
  #     #           operator: 'and'
  #     #         }
  #     #       }
  #     #     }
  #     #   }
  #     #   @search_definition[:highlight][:fields].update 'comments.body' => { fragment_size: 50 }
  #     # end
  #
  #     if options[:sort]
  #       @search_definition[:sort]  = { options[:sort] => 'desc' }
  #       @search_definition[:track_scores] = true
  #     end
  #
  #     unless query.blank?
  #       @search_definition[:suggest] = {
  #         text: query,
  #         suggest_title: {
  #           term: {
  #             field: 'provider.tokenized',
  #             suggest_mode: 'always'
  #           }
  #         },
  #         suggest_body: {
  #           term: {
  #             field: 'client.tokenized',
  #             suggest_mode: 'always'
  #           }
  #         }
  #       }
  #     end
  #
  #     __elasticsearch__.search(@search_definition)
  #   end
  end
end
