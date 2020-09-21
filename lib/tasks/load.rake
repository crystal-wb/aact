namespace :db do

  desc "Load the AACT database from ClinicalTrials.gov"
  task :load, [:days_back, :event_type, :full_featured] => :environment do |t, args|
    # The updater will default the params to run a relativey quick load:
    # incremental, not full featured, just a couple days
    Util::Updater.new(args).run
    Category.load_update({days_back: nil, condition: 'covid_19', make_tsv: true, grouping: 'covid_19'})
  end
  task :load_categories, [:days_back, :condition, :make_tsv, :grouping] => :environment do |t, args|
    Category.load_update(args)
  end
end
