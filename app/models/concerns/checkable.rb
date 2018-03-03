module Checkable
  extend ActiveSupport::Concern

  included do
    def get_landing_page_info
      return nil unless doi.present?

      return { "status" => 404, "content_type" => nil, "checked" => Time.zone.now.utc.iso8601 } unless
        url.present?

      response = Maremma.head(url, timeout: 5)
      if response.headers && response.headers["Content-Type"].present?
        content_type = response.headers["Content-Type"].split(";").first
      else
        content_type = nil
      end

      checked = Time.zone.now

      write_attribute(:last_landing_page_status, response.status)
      write_attribute(:last_landing_page_content_type, content_type)
      write_attribute(:last_landing_page_status_check, checked)

      { "status" => response.status,
        "content-type" => content_type,
        "checked" => checked.utc.iso8601 }
    end
  end
end
