class DoiSerializer
  include FastJsonapi::ObjectSerializer
  include MetricsHelper # mixes in your helper method as class method

  set_key_transform :camel_lower
  set_type :dois
  set_id :uid
  # don't cache dois, as works are cached using the doi model

  attributes :doi, :prefix, :suffix, :identifiers, :creators, :titles, :publisher, :container, :publication_year, :subjects, :contributors, :dates, :language, :types, :related_identifiers, :sizes, :formats, :version, :rights_list, :descriptions, :geo_locations, :funding_references, :xml, :url, :content_url, :metadata_version, :schema_version, :source, :is_active, :state, :reason, :landing_page, :created, :registered, :published, :updated, :citations, :views, :downloads
  attributes :prefix, :suffix, if: Proc.new { |object, params| params && params[:detail] }

  belongs_to :client, record_type: :clients
  has_many :media, record_type: :media, id_method_name: :uid, if: Proc.new { |object, params| params && params[:detail] && !params[:is_collection]}
  has_many :views, record_type: :events, if: Proc.new { |object, params| params && params[:events]}
  has_many :downloads, record_type: :events, if: Proc.new { |object, params| params && params[:events]}

  attribute :xml, if: Proc.new { |object, params| params && params[:detail] } do |object|
    begin
      Base64.strict_encode64(object.xml) if object.xml.present?
    rescue ArgumentError
      nil
    end
  end

  attribute :doi do |object|
    object.uid
  end

  attribute :creators do |object, params|
    # Always return an array of creators and affiliations
    # use new array format only if affiliation param present
    Array.wrap(object.creators).map do |c|
      c["affiliation"] = Array.wrap(c["affiliation"]).map do |a|
        if params[:affiliation]
          a
        else
          a["name"] 
        end
      end.compact
      c
    end.compact
  end

  attribute :contributors do |object, params|
    # Always return an array of contributors and affiliations
    # use new array format only if param present
    Array.wrap(object.contributors).map do |c|
      c["affiliation"] = Array.wrap(c["affiliation"]).map do |a|
        if params[:affiliation]
          a
        else
          a["name"] 
        end
      end.compact
      c
    end.compact
  end

  attribute :rights_list do |object|
    Array.wrap(object.rights_list)
  end

  attribute :container do |object|
    object.container || {}
  end

  attribute :types do |object|
    object.types || {}
  end

  attribute :state do |object|
    object.aasm_state
  end

  attribute :version do |object|
    object.version_info
  end

  attribute :published do |object|
    object.respond_to?(:published) ? object.published : nil
  end

  attribute :is_active do |object|
    object.is_active.to_s.getbyte(0) == 1 ? true : false
  end

  attribute :landing_page, if: Proc.new { |object, params| params[:current_ability] && params[:current_ability].can?(:read_landing_page_results, object) == true } do |object|
    object.landing_page
  end

  attribute :citations, if: Proc.new { |object, params|  params && params[:mix_in] == "metrics" }  do |object|
    doi_citations(object.uid)
  end

  attribute :views, if: Proc.new { |object, params|  params && params[:mix_in] == "metrics" }  do |object|
    doi_views(object.uid)
  end

  attribute :downloads, if: Proc.new { |object, params|  params && params[:mix_in] == "metrics" } do |object|
    doi_downloads(object.uid)
  end
end
