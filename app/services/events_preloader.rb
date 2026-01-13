# frozen_string_literal: true

# Service class to preload events for a batch of DOIs in a single query
# This dramatically reduces database queries from N*M (DOIs * Relationship Types) to 1-2 queries total
class EventsPreloader
  # Maximum number of DOIs to query at once to avoid database parameter limits
  CHUNK_SIZE = 1000

  def initialize(dois)
    @dois = Array(dois)
    @doi_map = {}
    @dois.each do |doi|
      @doi_map[doi.doi.upcase] = doi
      # Initialize preloaded_events array if not already set
      doi.preloaded_events ||= []
    end
  end

  # Preload all events for the batch of DOIs
  def preload!
    return if @dois.empty?

    doi_identifiers = @dois.map { |doi| doi.doi.upcase }.uniq
    return if doi_identifiers.empty?

    # Fetch events in chunks to avoid database parameter limits
    all_events = []
    doi_identifiers.each_slice(CHUNK_SIZE) do |chunk|
      events = Event.where(
        "source_doi IN (?) OR target_doi IN (?)",
        chunk, chunk
      ).to_a
      all_events.concat(events)
    end

    # Group events by DOI and assign to each Doi object
    all_events.each do |event|
      # Add event to source DOI's preloaded_events if it matches
      if event.source_doi.present?
        source_doi_obj = @doi_map[event.source_doi.upcase]
        source_doi_obj.preloaded_events << event if source_doi_obj
      end

      # Add event to target DOI's preloaded_events if it matches
      if event.target_doi.present?
        target_doi_obj = @doi_map[event.target_doi.upcase]
        target_doi_obj.preloaded_events << event if target_doi_obj
      end
    end

    # Ensure all DOIs have an array (even if empty)
    @dois.each do |doi|
      doi.preloaded_events ||= []
    end

    self
  end
end
