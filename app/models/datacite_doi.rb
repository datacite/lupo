# frozen_string_literal: true

class DataciteDoi < Doi
  include Elasticsearch::Model

  # use different index for testing
  if Rails.env.test?
    index_name "dois-test"
  elsif ENV["ES_PREFIX"].present?
    index_name "dois-#{ENV['ES_PREFIX']}"
  else
    index_name "dois"
  end
  # TODO switch index
  # if Rails.env.test?
  #   index_name "dois-datacite-test"
  # elsif ENV["ES_PREFIX"].present?
  #   index_name"dois-datacite-#{ENV["ES_PREFIX"]}"
  # else
  #   index_name "dois-datacite"
  # end
end
