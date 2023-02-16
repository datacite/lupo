# frozen_string_literal: true

namespace :enrich do
  desc "Enrich Clients with Subjects from re3data and converted to Field Of Science subjectScheme"
  task client_subjects: :environment do
    def enrich_client(client)
      re3data = DataCatalog.find_by_id(client.re3data_id).fetch(:data, []).first
      if re3data
        subs = re3data.subjects
        dfg_ids = subs.select { |subject|
          subject.scheme == "DFG"
        }.map { |subject|
          subject.text.split.first
        }
        fos_subjects = Bolognese::Utils.dfg_ids_to_fos(dfg_ids)
        client.subjects = fos_subjects.uniq
        client.save
      end
    end

    puts "Searching for disciplinary repositories with re3data_ids without subjects"
    search_results = Client.search("re3data_id:* AND -subjects:* AND -deleted_at:* AND repository_type:disciplinary")
    puts "Found #{search_results.records.count} repostitories.  Enriching now..."
    search_results.records.map do |c|
      enrich_client(c)
    end
    puts "Enrichment complete"
  end
end
