# Tenant tasks
namespace :tenant do

  namespace :agg do

    # Create aggregation schema
    desc "Create the aggregation schema"
    task :create => :environment do
      Ekylibre::Tenant.create_aggregation_schema!
    end

    # Drop aggregation schema
    desc "Drop the aggregation schema"
    task :drop => :environment do
      Ekylibre::Tenant.drop_aggregation_schema!
    end

  end

  desc "Drop a tenant"
  task :drop  => :environment do
    name = ENV["TENANT"]
    if Ekylibre::Tenant.exist?(name)
      Ekylibre::Tenant.drop(name)
    end
  end

  task :clear do
    require 'ekylibre/tenant'
    Ekylibre::Tenant.clear!
  end

  desc "List tenants"
  task :list => :environment do
    if Ekylibre::Tenant.list.any?
      puts Ekylibre::Tenant.list.to_sentence
    end
  end

end
