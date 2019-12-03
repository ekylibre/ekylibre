# Tenant tasks
namespace :tenant do
  namespace :multi_database do
    task drop: :environment do
      multi_database = ENV['MULTI_DATABASE'].to_i
      if multi_database > 0
        database = Rails.configuration.database_configuration[Rails.env]['database']
        (16 ** multi_database).times do |i|
          name = database + '_' + i.to_s(16).rjust(multi_database, '0')
          ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{name}")
        end
      end
    end

    task distribute: :environment do
      beginning = (ENV['FROM'] || ENV['MULTI_DATABASE'] || 0).to_i
      finish = (ENV['TO'] || ENV['MULTI_DATABASE'] || 1).to_i
      if beginning == finish
        puts 'Nothing to do. No change wanted.'
        exit 0
      end
      database = Rails.configuration.database_configuration[Rails.env]['database']
      now = Time.now.to_i.to_s(36)
      Ekylibre::Tenant.list.each do |tenant|
        start = Time.now
        source = Ekylibre::Tenant.database_for(tenant, beginning)
        destination = Ekylibre::Tenant.database_for(tenant, finish)
        puts "Moving schema #{tenant} from #{source} to #{destination}...".cyan
        # Warn if source and destination don't exist
        Ekylibre::Tenant.switch_to_database(source)
        source_exists = Apartment.connection.schema_exists? tenant
        Ekylibre::Tenant.create_database_for!(tenant, finish)
        Ekylibre::Tenant.switch_to_database(destination)
        destination_exists = Apartment.connection.schema_exists? tenant

        if source_exists && destination_exists
          puts "For #{tenant}, source and destination exist. Destination is removed".red
          Ekylibre::Tenant.with_pg_env(tenant) { `psql -c 'DROP SCHEMA "#{tenant}" CASCADE' #{destination}` }
        elsif !source_exists && !destination_exists
          puts "For #{tenant}, no source and no destination exist".red
          next
        end

        # Already migrated
        if !source_exists && destination_exists
          puts "For #{tenant}, no source and destination exist, schema already migrated".yellow
          next
        end

        dump = "tmp/distribute-#{beginning}-#{finish}-#{now}-#{tenant}.sql"

        # Dump source
        Ekylibre::Tenant.with_pg_env(tenant) { `pg_dump -x -O -f #{dump} -n '"#{tenant}"' #{source}` }

        # Restore destination
        Ekylibre::Tenant.with_pg_env(tenant) { `psql -f #{dump} #{destination}` }

        # Remove source and dump
        if ENV['DELETE_AFTER_DISTRIBUTE']
          Ekylibre::Tenant.with_pg_env(tenant) { `psql -c 'DROP SCHEMA "#{tenant}" CASCADE' #{source}` }
          FileUtils.rm_rf(dump)
        end

        puts "Schema #{tenant} moved from #{source} to #{destination} in #{Time.now - start} seconds".green
      end
    end
  end

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
      puts "Drop tenant: #{name.inspect.red}"
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

  desc 'Create a tenant with alone admin user (with TENANT, EMAIL, PASSWORD variable)'
  task init: :environment do
    tenant = ENV['TENANT']
    raise 'Need TENANT variable' unless tenant
    Ekylibre::Tenant.create(tenant) unless Ekylibre::Tenant.exist?(tenant)
    Ekylibre::Tenant.switch(tenant) do
      # Set basic preferences
      language = Nomen::Language.find(ENV['LANGUAGE'])
      Preference.set! :language, language ? language.name : 'fra'
      country = Nomen::Country.find(ENV['COUNTRY'])
      Preference.set! :country, country ? country.name : 'fr'
      currency = Nomen::Currency.find(ENV['CURRENCY'])
      Preference.set! :currency, currency ? currency.name : 'EUR'
      Preference.set! :map_measure_srs, ENV['MAP_MEASURE_SRS'] || ENV['SRS'] || 'WGS84'
      # Add user
      email = ENV['EMAIL'] || 'admin@ekylibre.org'
      user = User.find_by(email: email)
      if user
        puts 'No user created. Already initialized.'
      else
        attributes = {
          email: email,
          administrator: true,
          password: ENV['PASSWORD'] || '12345678',
          first_name: ENV['FIRST_NAME'] || 'Admin',
          last_name: ENV['LAST_NAME'] || tenant
        }
        attributes[:password_confirmation] = attributes[:password]
        User.create!(attributes)
        puts "Initialized with account #{email}."
        puts "Password is: #{attributes[:password]}" unless ENV['PASSWORD']
      end
    end
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

  task dump: :environment do
    archive = ENV['ARCHIVE'] || ENV['archive']
    tenant = ENV['TENANT'] || ENV['name']
    raise 'Need TENANT env variable to dump' unless tenant
    options = {}
    options[:path] = Pathname.new(archive) if archive
    options[:path] ||= Rails.root.join('tmp', 'archives') if tenant
    path_to_archive = options[:path] && options[:path].join("#{tenant}.zip")
    if path_to_archive && path_to_archive.exist? && ENV['FORCE'].to_i.zero?
      unless confirm("An archive #{path_to_archive.relative_path_from(Rails.root)} already exists. Do you want to overwrite it?", false)
        puts 'Nothing dumped'.yellow
        exit(0)
      end
    end
    puts "Dumping #{tenant}".yellow
    Ekylibre::Tenant.dump(tenant, options)
  end

  def confirm(question, default)
    puts question.yellow + ' Y/N'.red
    STDOUT.flush
    input = STDIN.gets.chomp
    case input.upcase
      when 'Y'
        return true
      when 'N'
        return false
      else
        return default
    end
  end

  task enable_support: :environment do
    tenant = ENV['TENANT']
    unless tenant.present?
      puts "TENANT varibale need to be set".yellow
      exit(1)
    end

    unless Ekylibre::Tenant.exist?(tenant)
      puts "TENANT #{tenant} does not exist.".yellow
      exit(1)
    end

    password = ENV['PASSWORD']
    password ||= SecureRandom.urlsafe_base64(12)

    Ekylibre::Tenant.switch tenant do
      user = User.find_by(email: "support@ekylibre.com")
      if user.present?
        user.update! password: password
      else
        first_name = "Support"
        last_name = "Ekylibre"

        Ekylibre::Record::Base.transaction do
          person = Entity.find_by(first_name: first_name, last_name: last_name)
          person ||= Entity.create!(first_name: first_name, last_name: last_name, nature: :contact)

          User.create!(email: "support@ekylibre.com", language: :fra, administrator: true, first_name: first_name, last_name: last_name, password: password, person: person)
        end
      end
      puts "Support enabled. Password: ".green + password.red
    end
  end

  task restore: :environment do
    if Rails.env.production? && !ENV['DANGEROUS_MODE']
      raise Ekylibre::ForbiddenImport, 'No restore is allowed on the production server.'
    end
    archive = ENV['ARCHIVE'] || ENV['archive']
    tenant = ENV['TENANT'] || ENV['name']
    options = {}
    if tenant.present?
      archive ||= Rails.root.join('tmp', 'archives', "#{tenant}.zip")
      options[:tenant] = tenant
    end
    archive = Pathname.new(archive) unless archive.is_a? Pathname
    raise 'Need ARCHIVE env variable to find archive' unless archive
    if Ekylibre::Tenant.exist?(tenant) && ENV['FORCE'].to_i.zero?
      warnings = ["Tenant \"#{tenant}\" already exists. Do you really want to erase it and restore archive?",
                  'Really sure?']
      if Rails.env.production?
        warnings << 'Reeeeeaaaaally sure?'
        warnings << 'For sure?'
        warnings << 'There\'ll be no coming back. Can you confirm once more?'
      end
      confirmed = warnings.reduce(true) do |choice, question|
        choice && confirm(question, false)
      end
      unless confirmed
        puts 'Nothing restored'.yellow
        exit(0)
      end
    end
    puts "Restoring #{tenant}".yellow
    Ekylibre::Tenant.restore(archive, options)
  end

  namespace :restore do
    task easy_login: :restore do
      Ekylibre::Tenant.switch!(ENV['TENANT'] || ENV['name'])
      puts
      puts '== ' + 'Modifying User'.yellow + '=' * 61
      User.first.update!(email: 'admin@ekylibre.org', password: '12345678')
      puts
      puts 'Done!'.yellow
      puts
    end
  end

  desc 'List tenants'
  task list: :environment do
    puts Ekylibre::Tenant.list.join(', ') if Ekylibre::Tenant.list.any?
  end
end
