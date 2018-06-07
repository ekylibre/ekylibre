# Tenant tasks
namespace :shapes do
  desc 'Find invalid productions support shapes (resolve GEOSUnaryUnion: TopologyException error)'
  task find_invalid_productions: :environment do
    tenant = ENV['TENANT']

    raise 'Need TENANT variable' unless tenant

    puts "Switch to tenant #{tenant}"
    Ekylibre::Tenant.switch(tenant) do
      invalid_productions_ids = find_invalid_productions

      puts "Invalid productions count : #{invalid_productions_ids.count}"
      puts "Invalid productions ids : #{invalid_productions_ids}"
    end
  end

  desc 'Make valid invalid productions support shapes (resolve GEOSUnaryUnion: TopologyException error)'
  task make_valid_productions: :environment do
    tenant = ENV['TENANT']

    raise 'Need TENANT variable' unless tenant

    puts "Switch to tenant #{tenant}"
    Ekylibre::Tenant.switch(tenant) do
      invalid_productions_ids = find_invalid_productions

      puts "Invalid productions count : #{invalid_productions_ids.count}"

      make_valid_productions(invalid_productions_ids)

      puts 'Task finished!'
    end
  end

  def find_invalid_productions
    not_valid_production_ids = []
    valid_activity_productions_ids = []

    activity_productions_ids = ActivityProduction.all.map(&:id)

    (1...ActivityProduction.count).each do |index|
      production_ids = ActivityProduction.first(index).map(&:id)
      activity_production_id = production_ids.last

      not_valid_production_ids.each do |production_id|
        production_ids.delete_at(production_ids.index(production_id))
      end

      request = "SELECT ST_AsEWKT(ST_Union(support_shape)) FROM activity_productions WHERE id IN (#{production_ids.join(',')})"

      begin
        ActiveRecord::Base.connection.execute(request)
      rescue => exception
        not_valid_production_ids << activity_production_id
      end
    end

    not_valid_production_ids
  end

  def make_valid_productions(production_ids)
    production_ids.each do |production_id|
      request = "UPDATE activity_productions SET support_shape = ST_MakeValid(support_shape) WHERE id = #{production_id}"

      ActiveRecord::Base.connection.execute(request)
    end
  end
end
