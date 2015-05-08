desc "Import a file into given tenant"
task :import, [:type, :file] => :environment do |args|
  ActiveExchanger::Base.import(args[:type], args[:file])
end
