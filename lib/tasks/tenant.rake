# 

namespace :tenant do

  task :aggregate => :environment do
    Ekylibre::Tenant.build_aggregated_schema!
  end

  task :drop => :environment do
    name = ENV["TENANT"]
    if Ekylibre::Tenant.exist?(name)
      Ekylibre::Tenant.drop(name)
    end
  end

end
