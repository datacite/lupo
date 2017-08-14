ActiveModel::Serializer.config.adapter = ActiveModelSerializers::Adapter::JsonApi
ActiveModel::Serializer.config.include_data_default = :if_sideloaded
ActiveSupport.on_load(:action_controller) do
  require 'active_model_serializers/register_jsonapi_renderer'
end
