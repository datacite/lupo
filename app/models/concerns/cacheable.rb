module Cacheable
  extend ActiveSupport::Concern

  included do
    def cached_data_center_response(id, options={})
      Rails.cache.fetch("data_center_response/#{id}", expires_in: 7.days) do
        Datacenter.where(symbol: id).select(:id, :symbol, :name, :created).first
      end
    end

    def cached_members
      Rails.cache.fetch("members", expires_in: 1.day) do
        Member.all.select(:id, :symbol, :name, :created)
      end
    end

    def cached_member_response(id, options={})
      Rails.cache.fetch("member_response/#{id}", expires_in: 7.days) do
        Member.where(symbol: id).select(:id, :symbol, :name, :created).first
      end
    end
  end

  module ClassMethods
    def cached_datasets
      Rails.cache.fetch("datasets", expires_in: 1.day) do
        Dataset.all
      end
    end

    def cached_datasets_options(options={})
      Rails.cache.fetch("records_datasets", :expires_in => 1.day) do
        collection = cached_datasets
        # collection = collection.all unless options.values.include?([nil,nil])
        collection = collection.where('extract(year  from created) = ?', options[:year]) if options[:year].present?
        collection = collection.where(datacentre:  Datacenter.find_by(symbol: options[:datacenter_id]).id) if options[:datacenter_id].present?
        collection
      end
    end

    def cached_datacenters
      Rails.cache.fetch("datacenters", expires_in: 1.month) do
        Datacenter.all
      end
    end

    # def cached_members_response(options={})
    #   Rails.cache.fetch("member_response", expires_in: 1.day) do
    #     Base::DB[:allocator].select(:id, :symbol, :name, :created).all
    #   end
    # end

    def cached_datasets_datacenters_join(options={})
      Rails.cache.fetch("datacenters", expires_in: 1.day) do
        Dataset.joins(:datacenters).where("datacenter.symbol" => "dataset.allocator")
      end
    end

    def cached_datacenters_response(options={})
      Rails.cache.fetch("datacenters_response", expires_in: 1.day) do
        # collection = cached_datasets_datacenters_joins
        collection.each do |line|
          dc = Datacenter.find(line[:datacentre])
          line[:datacenter_id] = dc.uid.downcase
          line[:datacenter_name] = dc.name
        end

        collection.map{|doi| { id: doi[:id],  datacenter_id: doi[:datacenter_id],  name: doi[:datacenter_name] }}.group_by { |d| d[:datacenter_id] }.map{ |k, v| { id: k, title: v.first[:name], count: v.count} }
      end
    end

    def cached_total_response(options={})
      Rails.cache.fetch("total_response", expires_in: 1.day) do
        query = self.ds.where{(is_active = true) & (allocator > 100)}
        query.count
      end
    end

    # def cached_years_response(options={})
    #   Rails.cache.fetch("years_response", expires_in: 1.day) do
    #     query = self.ds.where{(is_active = true) & (allocator > 100)}
    #     years = query.group_and_count(Sequel.extract(:year, :created)).all
    #     years.map { |y| { id: y.values.first.to_s, title: y.values.first.to_s, count: y.values.last } }
    #          .sort { |a, b| b.fetch(:id) <=> a.fetch(:id) }
    #   end
    # end

    def cached_years_response
      Rails.cache.fetch("years_datasets", :expires_in => 1.hour) do
        collection = cached_datasets
        collection.map{|doi| { id: doi[:id],  year: doi[:created].year }}.group_by { |d| d[:year] }.map{ |k, v| { id: k, title: k, count: v.count} }
      end
    end

    def cached_years_by_member_response(id, options={})
      Rails.cache.fetch("years_response", expires_in: 1.day) do
        query = self.ds.where(is_active: true, allocator: id)
        years = query.group_and_count(Sequel.extract(:year, :created)).all
        years.map { |y| { id: y.values.first.to_s, title: y.values.first.to_s, count: y.values.last } }
             .sort { |a, b| b.fetch(:id) <=> a.fetch(:id) }
      end
    end

    def cached_allocators_response(options={})
      Rails.cache.fetch("allocator_response", expires_in: 1.day) do
        query = self.ds.where{(is_active = true) & (allocator > 100)}
        allocators = query.group_and_count(:allocator).all.map { |a| { id: a[:allocator], count: a[:count] } }
        members = cached_members_response
        members = (allocators + members).group_by { |h| h[:id] }.map { |k,v| v.reduce(:merge) }.select { |h| h[:count].present? }
      end
    end

    def cached_data_centers_response(options={})
      Rails.cache.fetch("data_center_response", expires_in: 1.day) do
        query = self.ds.where{(is_active = true) & (allocator > 100)}
        query.limit(25).offset(0).order(:name)
      end
    end

    def cached_data_centers_by_member_response(id, options={})
      Rails.cache.fetch("data_center_by_member_response/#{id}", expires_in: 1.day) do
        query = self.ds.where(is_active: true, allocator: id)
        query.limit(25).offset(0).order(:name)
      end
    end
  end
end
