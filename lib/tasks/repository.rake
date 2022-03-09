namespace :repository do
  desc "Load all Clients into Reference Repostories"
  task load_client_repos: :environment do
    puts "Processing Client Repositories"
    progressbar = ProgressBar.create(
      format: "%a %e %P% Processed: %c from %C %t",
      title: "Client Repositories",
      total: Client.all.count
    )
    Client.all.each do |c|
      progressbar.increment
      ReferenceRepository.find_or_create_by(
        client_id: c.symbol,
        re3doi: c.re3data_id
      )
    end
  end

  desc "Load all Re3data Repositories into Reference Repostories"
  task :load_re3data_repos, [:pages] => :environment do |t, args|
    pages = (args[:pages] || 3).to_i
    re3repos = []
    (1..pages).each do |page|
      puts "Fetching Re3Data Repositories: Fetch Group #{page}"
      re3repos += DataCatalog.query("", limit: 1000, offset:page).fetch(:data, [])
    end
    re3repos.uniq!
    puts "Processing Re3Data Repositories"
    progressbar = ProgressBar.create(
      format: "%a %e %P% Processed: %c from %C %t",
      title: "Re3data Repositories",
      total: re3repos.length
    )
    re3repos.each  do |repo|
      progressbar.increment
      doi = repo.id&.gsub('https://doi.org/','')
      if not doi.blank?
        ReferenceRepository.find_or_create_by(
          re3doi: doi
        )
      end
    end
  end
end
