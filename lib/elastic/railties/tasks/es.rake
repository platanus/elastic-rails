namespace :es do
  desc "Elastic: Updates indices mappings"
  task :remap, [:index] => :environment do |_, args|
    Elastic.configure logger: Logger.new(STDOUT)
    Elastic.remap args.index
  end

  desc "Elastic: Updates indices mappings, rebuilding index if necessary"
  task :migrate, [:index] => :environment do |_, args|
    Elastic.configure logger: Logger.new(STDOUT)
    Elastic.migrate args.index
  end

  desc "Elastic: Rebuilds indices from source data"
  task :reindex, [:index] => :environment do |_, args|
    Elastic.configure logger: Logger.new(STDOUT)
    Elastic.reindex args.index
  end

  desc "Elastic: Lists indices stats"
  task :stats, [:index] => :environment do |_, args|
    Elastic.configure logger: Logger.new(STDOUT)
    Elastic.stats args.index
  end
end
