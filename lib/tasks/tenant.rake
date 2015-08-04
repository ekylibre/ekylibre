# Tenant tasks
namespace :tenant do
  namespace :agg do
    # Create aggregation schema
    desc 'Create the aggregation schema'
    task create: :environment do
      Ekylibre::Tenant.create_aggregation_schema!
    end

    # Drop aggregation schema
    desc 'Drop the aggregation schema'
    task drop: :environment do
      Ekylibre::Tenant.drop_aggregation_schema!
    end
  end

  desc 'Drop a tenant (with TENANT variable)'
  task drop: :environment do
    name = ENV['TENANT'] || ENV['name']
    if Ekylibre::Tenant.exist?(name)
      Ekylibre::Tenant.drop(name)
    else
      puts "Unknown tenant: #{name.inspect.red}"
    end
  end

  desc 'Create a tenant (with TENANT variable)'
  task create: :environment do
    name = ENV['TENANT'] || ENV['name']
    Ekylibre::Tenant.create(name) unless Ekylibre::Tenant.exist?(name)
  end

  desc 'Rename a tenant (with OLD/NEW variables)'
  task rename: :environment do
    old = ENV['OLD'] || ENV['name']
    new = ENV['NEW']
    if Ekylibre::Tenant.exist?(old)
      Ekylibre::Tenant.rename(old, new)
    else
      puts "Unknown tenant: #{old.inspect.red}"
    end
  end

  task :clear do
    require 'ekylibre/tenant'
    Ekylibre::Tenant.clear!
  end

  desc 'List tenants'
  task list: :environment do
    puts Ekylibre::Tenant.list.join(', ') if Ekylibre::Tenant.list.any?
  end
end
