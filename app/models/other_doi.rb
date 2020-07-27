class OtherDoi < Doi
  include Elasticsearch::Model
  
  # use different index for testing
  if Rails.env.test?
    index_name "dois-other-test"
  elsif ENV["ES_PREFIX"].present?
    index_name"dois-other-#{ENV["ES_PREFIX"]}"
  else
    index_name "dois-other"
  end
end
