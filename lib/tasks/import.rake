desc 'Import a file into given tenant'
task :import, [:type, :file] => :environment do |args|
  Ekylibre::Tenant.switch(ENV['TENANT']) do
    ActiveExchanger::Base.import(args[:type], args[:file])
  end
end
