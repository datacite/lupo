class EventRegistrantUpdateByIdJob < ActiveJob::Base
  queue_as :lupo_background


  rescue_from ActiveJob::DeserializationError, Elasticsearch::Transport::Transport::Errors::BadRequest do |error|
    logger = Logger.new(STDOUT)
    logger.error error.message
  end

  def perform(id, options={})
    logger = Logger.new(STDOUT)
   
    item = Event.where(uuid: id).first
    return false unless item.present?
    logger.info "djdjdj"
    logger.info id
    logger.info item.source_id

    
    case item.source_id 
    when "datacite-crossref"
      registrant_id = get_crossref_member_id(item.obj_id) if get_doi_ra(item.obj_id) == "Crossref"
      logger.info registrant_id

      obj = item.obj.merge("registrant_id" => registrant_id) unless registrant_id.nil?
      logger.info obj
      item.update_attributes(obj: obj) if obj.present?
    when "crossref"
      registrant_id = get_crossref_member_id(item.subj) if get_doi_ra(item.subj) == "Crossref"
      logger.info registrant_id

      subj = item.subj.merge("registrant_id" => registrant_id) unless registrant_id.nil?
      logger.info subj
      item.update_attributes(subj: subj) if subj.present?
    end

    logger.error item.errors.full_messages.map { |message| { title: message } } if item.errors.any?
    logger.info "#{item.uuid} Updated" if item.errors.blank? && registrant_id
  end

  def get_crossref_member_id(id, options={})
    logger = Logger.new(STDOUT)
    doi = doi_from_url(id)
    # return "crossref.citations" unless doi.present?
  
    url = "https://api.crossref.org/works/#{Addressable::URI.encode(doi)}?mailto=info@datacite.org"	
    sleep(0.01) # to avoid crossref rate limitting
    response =  Maremma.get(url, host: true)	
    logger.info "[Crossref Response] [#{response.status}] for DOI #{doi} metadata"
    return "" if response.status == 404  ### for cases when DOI is not in the crossreaf api 
    return "crossref.citations" if response.status != 200	 ### for cases any other errors 

    message = response.body.dig("data", "message")

    "crossref.#{message["member"]}"
  end 

  def get_doi_ra(doi)
    prefix = validate_prefix(doi)
    return nil if prefix.blank?

    url = "https://doi.org/ra/#{prefix}"
    result = Maremma.get(url)

    result.body.dig("data", 0, "RA")
  end

  def validate_prefix(doi)
    Array(/\A(?:(http|https):\/(\/)?(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}).*\z/.match(doi)).last
  end

  def doi_from_url(url)
    if /\A(?:(http|https):\/\/(dx\.)?(doi.org|handle.test.datacite.org)\/)?(doi:)?(10\.\d{4,5}\/.+)\z/.match(url)
      uri = Addressable::URI.parse(url)
      uri.path.gsub(/^\//, '').downcase
    end
  end
end
