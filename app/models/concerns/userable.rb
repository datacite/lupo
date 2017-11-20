module Userable
  extend ActiveSupport::Concern

  included do
    def remove_users(id: nil, jwt: nil)
      result = Maremma.get user_url
      Rails.logger.info result.inspect
      Array.wrap(result.body["data"]).each do |user|
        url = ENV["VOLPINO_URL"] + "/users/" + user.fetch("id")
        data = { "data" => { "attributes" => { id => nil },
                             "type" => "users" } }

        result = Maremma.patch(url, content_type: 'application/vnd.api+json', accept: 'application/vnd.api+json', bearer: jwt, data: data.to_json)
        Rails.logger.info result.inspect
      end
    end
  end
end
