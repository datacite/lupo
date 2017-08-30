module Dateable
  extend ActiveSupport::Concern

  module ClassMethods
    def get_solr_date_range(from_date, until_date)
      from_date_string = get_datetime_from_input(from_date) || "*"
      until_date_string = get_datetime_from_input(until_date, until_date: true) || "*"
      until_date_string = get_datetime_from_input(from_date, until_date: true) if until_date_string != "*" && until_date_string < from_date_string

      "[" + from_date_string + " TO " + until_date_string + "]"
    end

    def get_datetime_from_input(iso8601_time, options={})
      return nil unless iso8601_time.present?

      time = get_datetime_from_iso8601(iso8601_time, options)
      return nil unless time.present?

      time.iso8601
    end

    # parsing of incomplete iso8601 timestamps such as 2015-04 is broken
    # in standard library
    # return nil if invalid iso8601 timestamp
    def get_datetime_from_iso8601(iso8601_time, options={})
      if options[:until_date]
        if iso8601_time[8..9].present?
          ISO8601::DateTime.new(iso8601_time).to_time.utc.at_end_of_day
        elsif iso8601_time[5..6].present?
          ISO8601::DateTime.new(iso8601_time).to_time.utc.at_end_of_month
        else
          ISO8601::DateTime.new(iso8601_time).to_time.utc.at_end_of_year
        end
      else
        ISO8601::DateTime.new(iso8601_time).to_time.utc
      end
    rescue
      nil
    end
  end
end
