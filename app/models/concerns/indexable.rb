module Indexable
  extend ActiveSupport::Concern

  included do
    before_destroy { Shoryuken::Client.queues(Rails.env + '_elastic').send_message(message_body: { data: self.to_jsonapi, action: "delete" }) }
    after_create { Shoryuken::Client.queues(Rails.env + '_elastic').send_message(message_body: { data: self.to_jsonapi, action: "create" }) }
    after_update { Shoryuken::Client.queues(Rails.env + '_elastic').send_message(message_body: { data: self.to_jsonapi, action: "update" }) }
  end
end
