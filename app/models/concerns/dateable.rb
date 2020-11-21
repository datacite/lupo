module Dateable
  extend ActiveSupport::Concern

  included do
    def get_date(dates, date_type)
      dd = Array.wrap(dates).detect { |d| d["dateType"] == date_type } || {}
      dd.fetch("date", nil)
    end

    def set_date(dates, date, date_type)
      dd = Array.wrap(dates).detect { |d| d["dateType"] == date_type } || { "dateType" => date_type }
      dd["date"] = date
    end

    def get_resource_type(types, type)
      types[type]
    end

    def set_resource_type(types, text, type)
      types[type] = text
    end
  end

  module ClassMethods
    def get_solr_date_range(from_date, until_date)
      from_date_string = get_datetime_from_input(from_date) || "*"
      until_date_string = get_datetime_from_input(until_date, until_date: true) || "*"
      until_date_string = get_datetime_from_input(from_date, until_date: true) if until_date_string != "*" && until_date_string < from_date_string

      "[" + from_date_string + " TO " + until_date_string + "]"
    end

    def get_datetime_from_input(iso8601_time, options = {})
      return nil if iso8601_time.blank?

      time = get_datetime_from_iso8601(iso8601_time, options)
      return nil if time.blank?

      time.iso8601
    end

    def get_date_from_parts(year, month = nil, day = nil)
      return nil if year.blank?

      iso8601_time = [year.to_s.rjust(4, "0"), month.to_s.rjust(2, "0"), day.to_s.rjust(2, "0")].reject { |part| part == "00" }.join("-")
      get_datetime_from_iso8601(iso8601_time)
    end

    # parsing of incomplete iso8601 timestamps such as 2015-04 is broken
    # in standard library
    # return nil if invalid iso8601 timestamp
    def get_datetime_from_iso8601(iso8601_time, options = {})
      if options[:until_date]
        if iso8601_time[8..9].present?
          ISO8601::DateTime.new(iso8601_time).to_time.utc.at_end_of_day.iso8601
        elsif iso8601_time[5..6].present?
          ISO8601::DateTime.new(iso8601_time).to_time.utc.at_end_of_month.iso8601
        else
          ISO8601::DateTime.new(iso8601_time).to_time.utc.at_end_of_year.iso8601
        end
      else
        ISO8601::DateTime.new(iso8601_time).to_time.utc.iso8601
      end
    rescue StandardError
      nil
    end
  end
end
