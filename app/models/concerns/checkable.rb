module Checkable
  extend ActiveSupport::Concern

  module ClassMethods
    def get_landing_page_info(doi: nil, url: nil)
      url = doi.present? ? doi.url : url
      return { "status" => 404, "content_type" => nil, "checked" => Time.zone.now.utc.iso8601 } unless
        url.present?

      response = Maremma.head(url, timeout: 5)
      if response.headers && response.headers["Content-Type"].present?
        content_type = response.headers["Content-Type"].split(";").first
      else
        content_type = nil
      end

      checked = Time.zone.now

      doi.update_attributes(last_landing_page_status: response.status,
                            last_landing_page_content_type: content_type,
                            last_landing_page_status_check: checked) if doi.present?

      { "status" => response.status,
        "content-type" => content_type,
        "checked" => checked.utc.iso8601 }
    end
  end
end
