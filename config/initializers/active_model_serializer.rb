# frozen_string_literal: true

require "active_model_serializers"
ActiveSupport::Notifications.unsubscribe(ActiveModelSerializers::Logging::RENDER_EVENT)
