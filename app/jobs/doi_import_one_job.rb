class DoiImportOneJob < ActiveJob::Base
    queue_as :lupo_background

    rescue_from(Elasticsearch::Transport::Transport::Errors::BadRequest) do |e|
        logger = Logger.new(STDOUT)
        logger.info("[Import DOI] Failed to index a doi, exception was: " + e.message)
    end

    def perform(doi)
        logger = Logger.new(STDOUT)
        logger.info("[Import DOI] Attempting to import doi: " + doi)
        Doi.import_one(doi_id: doi)
    end
  end