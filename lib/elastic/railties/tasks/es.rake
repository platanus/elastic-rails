namespace :es do
  desc "Elastic: Updates indices mappings"
  task migrate: :environment do
    Rails.logger = Logger.new(STDOUT)
    Elastic.migrate
  end

  desc "Elastic: Rebuilds indices from source data"
  task reindex: :environment do
    Rails.logger = Logger.new(STDOUT)
    Elastic.reindex
  end

  desc "Elastic: Lists indices stats"
  task stats: :environment do
    Rails.logger = Logger.new(STDOUT)
    Elastic.stats
  end
end
