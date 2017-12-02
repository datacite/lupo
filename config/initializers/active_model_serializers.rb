ActiveModelSerializers.config.adapter = ActiveModelSerializers::Adapter::JsonApi
ActiveModelSerializers.config.include_data_default = :if_sideloaded

# disable pagination links as it requires expensive count queries on the database
ActiveModelSerializers.config.jsonapi_pagination_links_enabled = false

ActiveSupport.on_load(:action_controller) do
  require 'active_model_serializers/register_jsonapi_renderer'
end
