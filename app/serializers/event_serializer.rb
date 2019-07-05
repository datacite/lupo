require 'benchmark'


class EventSerializer
  include FastJsonapi::ObjectSerializer
  include BatchLoaderHelper

  set_key_transform :camel_lower
  set_type :events
  set_id :uuid
  
  attributes :subj_id, :obj_id, :source_id, :relation_type_id, :total, :message_action, :source_token, :license, :occurred_at, :timestamp
  
  has_many :dois, record_type: :dois, serializer: DoiSerializer, id_method_name: :uid do |object|
    # logger = Logger.new(STDOUT)
    # bmp = Benchmark.ms {
    #   load_doi(object)
    # }
    # if bmp > 10000
    #   logger.warn "[Benchmark Warning] batchloading " + bmp.to_s + " ms"
    # else
    #   logger.info "[Benchmark] batchloading " + bmp.to_s + " ms"
    # end
    # puts "ouside"
    # puts object.uuid
    load_doi(object)
  end
  
  attribute :timestamp, &:updated_at
end
