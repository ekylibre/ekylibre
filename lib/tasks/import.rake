desc "Import a file into given tenant"
task :import, [:type, :file] => :environment do |args|
  Exchanges.import(args[:type], args[:file])
end
