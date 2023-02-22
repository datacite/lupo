# frozen_string_literal: true

namespace :enrich do
  desc "Enrich Clients with Subjects from re3data and converted to Field Of Science subjectScheme"
  task client_subjects: :environment do
    def all_clients_from_query(query: nil)
      # Loop through all clients
      page = { size: 1_000, number: 1 }
      response = Client.query(query, page: page)
      clients = response.records.to_a

      total = response.records.total
      total_pages = page[:size] > 0 ? (total.to_f / page[:size]).ceil : 0

      # keep going for all pages
      page_num = 2
      while page_num <= total_pages
        page = { size: 1_000, number: page_num }
        response = self.query(query, page: page)
        clients = clients + response.records.to_a
        page_num += 1
      end
      clients
    end

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
    clients = all_clients_from_query(query: "re3data_id:* AND -subjects:* AND -deleted_at:* AND repository_type:disciplinary")
    puts "Found #{clients.count} repostitories."
    if clients.count > 0
      puts "Enriching now..."
      clients.each do |c|
        enrich_client(c)
      end
      puts "Enrichment complete"
    else
      puts "Skipping enrichment"
    end
  end
end
