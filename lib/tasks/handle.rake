namespace :handle do
  desc 'Get DOIs by prefix'
  task :get_dois => :environment do
    if ENV['PREFIX'].nil?
      puts "ENV['PREFIX'] is required."
      exit
    end

    response = Doi.get_dois(prefix: ENV['PREFIX'])
    puts (response.body.dig("data", "handles") || []).join("\n")
    puts "Found " + (response.body.dig("data", "totalCount") || "0") + " DOIs with prefix #{ENV['PREFIX']}."
  end

  desc 'Get DOI'
  task :get_doi => :environment do
    if ENV['DOI'].nil?
      puts "ENV['DOI'] is required."
      exit
    end

    response = Doi.get_doi(doi: ENV['DOI'])
    url = response.body.dig('data', 'values', 0, 'data', 'value')
    puts "DOI #{ENV['DOI']} uses URL #{url}" if url.present?
  end

  desc 'Delete DOI'
  task :delete_doi => :environment do
    if ENV['DOI'].nil?
      puts "ENV['DOI'] is required."
      exit
    elsif !ENV['DOI'].start_with?("10.5072")
      puts "Only DOIs with prefix 10.5072 can be deleted."
      exit
    end

    response = Doi.delete_doi(doi: ENV['DOI'])
    puts "Deleted DOI #{ENV['DOI']}." if response.body.dig('data', 'responseCode') == 1
  end

  desc 'Delete DOIs with test prefix'
  task :delete_dois => :environment do
    if ENV['PREFIX'].nil?
      puts "ENV['PREFIX'] is required."
      exit
    elsif ENV['PREFIX'] != "10.5072"
      puts "Only DOIs with prefix 10.5072 can be deleted."
      exit
    end

    response = Doi.get_dois(prefix: "10.5072")
    dois = response.body.dig("data", "handles") || []
    puts "Found #{dois.length} DOIs."
    dois.each do |doi|
      response = Doi.delete_doi(doi: doi)
      puts "Deleted DOI #{doi}." if response.body.dig('data', 'responseCode') == 1
    end
  end
end