desc 'Import a file into given tenant'
task :import, %i[type file] => :environment do |args|
  Ekylibre::Tenant.switch(ENV.fetch('TENANT', nil)) do
    ActiveExchanger::Base.import(args[:type], args[:file])
  end
end
