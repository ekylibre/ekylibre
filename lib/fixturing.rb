require 'active_record/fixtures'

module Fixturing
  class << self
    def current_version
      CSV.read(migrations_file).last.first.to_i
    end

    def directory
      Pathname.new(ActiveRecord::Tasks::DatabaseTasks.fixtures_path)
    end

    def migrations_file
      directory.join(migrations_table)
    end

    def migrations_table
      'schema_migrations'
    end

    # Returns true if current_version is last DB version
    def up_to_date?(options = {})
      version = options[:version] || current_version
      version == ActiveRecord::Migrator.last_version
    end

    def tables_from_files(options = {})
      path = options[:path] || directory
      Dir.glob(path.join('*.yml')).collect do |f|
        Pathname.new(f).basename('.*').to_s
      end.sort
    end

    def restore(tenant, options = {})
      path = options[:path] || directory
      version = options[:version] || current_version
      verbose = !options[:verbose].is_a?(FalseClass)
      Apartment.connection.execute("DROP SCHEMA IF EXISTS \"#{tenant}\" CASCADE")
      Apartment.connection.execute("CREATE SCHEMA \"#{tenant}\"")
      Ekylibre::Tenant.add(tenant)
      Apartment.connection.execute("SET search_path TO '#{tenant}', postgis")
      Ekylibre::Tenant.migrate(tenant, to: version)
      table_names = tables_from_files(path: path)
      say 'Load fixtures' if verbose
      Ekylibre::Tenant.switch!(tenant)
      ActiveRecord::FixtureSet.reset_cache
      ActiveRecord::Base.connection.schema_cache.clear!
      ActiveRecord::FixtureSet.create_fixtures(path, table_names)
      migrate(tenant, origin: version) unless up_to_date?(version: version)
    end

    def reverse(tenant, steps = 1)
      restore(tenant)
      rollback(tenant, steps)
    end

    # Dump data of database into fixtures
    def dump(tenant, options = {})
      Ekylibre::Tenant.switch!(tenant)

      migrate(tenant) unless up_to_date?

      if options[:backup]
        backup = "#{directory}~"
        FileUtils.rm_rf(backup)
        FileUtils.cp_r(directory, backup)
      end

      Dir[directory.join('*.yml').to_s].each do |f|
        FileUtils.rm_rf(f)
      end

      version = extract(path: directory)

      # Updates fixtures name with models
      beautify_fixture_ids(path: directory)

      # Clean annotations
      Clean::Annotations.run(only: :fixtures, verbose: false)

      # Dump last schema_migrations into schema_migrations file
      File.open(migrations_file, 'wb') do |f|
        f.write version
      end
    end

    # Extract data from DB into given path or test/fixtures by default
    # Returns version of DB (as integer)
    def extract(options = {})
      path = options[:path] || directory
      Ekylibre::Schema.tables.each do |table, columns|
        records = {}
        ActiveRecord::Base.connection.select_all("SELECT * FROM #{table} ORDER BY id").each do |row|
          record = {}
          row.sort.each do |attribute, value|
            if columns[attribute]
              unless value.nil?
                type = columns[attribute].type
                type = columns[attribute].limit[:type] if columns[attribute].limit.is_a?(Hash)
                record[attribute] = convert_value(value, type.to_sym)
              end
            else
              puts "Cannot find column '#{attribute}' in #{table}. Run `rake clean:schema`.".red
            end
          end
          records["#{table}_#{row['id'].rjust(3, '0')}"] = record
        end

        File.open(path.join("#{table}.yml"), 'wb') do |f|
          f.write records.to_yaml.gsub(/[\ \t]+\n/, "\n")
        end
      end

      version = ActiveRecord::Base.connection.select_value("SELECT * FROM #{migrations_table} ORDER BY 1 DESC")
      version.to_i
    end

    def migrate(tenant, options = {})
      target = ActiveRecord::Migrator.last_version
      origin = options[:origin] || current_version
      if target != origin
        say 'Migrate fixtures from ' + origin.inspect + ' to ' + target.inspect
        Ekylibre::Tenant.switch(tenant) do
          ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths, target)
        end
      else
        say 'No more migrations', :green
      end
    end

    def rollback(tenant, steps = 1)
      say "Rollback (Steps count: #{steps})"
      Ekylibre::Tenant.switch(tenant) do
        ActiveRecord::Migrator.rollback(ActiveRecord::Migrator.migrations_paths, steps)
      end
    end

    def say(text, color = :yellow)
      size = text.size
      puts '== ' + text.send(color) + ' ' + '=' * (79 - size - 4) + "\n\n"
    end

    # Convert reflection to hard representation in fixtures
    #   my_thing: things_001             => my_thing_id: 1
    #   my_polymorph: things_001 (Thing) => my_polymorph_id: 1
    #                                       my_polymorph_type: Thing
    def columnize_keys
      # Load and prepare fixtures
      data = {}
      Ekylibre::Schema.tables.each do |table, _columns|
        records = YAML.load_file(directory.join("#{table}.yml"))
        ids = records.values.collect { |a| a['id'] }.compact.map(&:to_i)
        records.each do |record, attributes|
          next if attributes['id']
          id = record.split('_').last.to_i
          attributes['id'] = ids.include?(id) ? (1..(ids.max + 10)).to_a.detect { |x| !ids.include?(x) } : id
          ids << attributes['id']
        end
        data[table.to_s] = records
      end

      # Convert
      Ekylibre::Schema.tables.each do |table, columns|
        columns.each do |column, definition|
          next unless references = definition[:references]
          if references.is_a?(Symbol)
            # Standard reflection case
            foreign_model = references.to_s.camelcase.constantize
            puts references.inspect.red unless data[foreign_model.table_name]
            data[table.to_s].each do |record, attributes|
              reflection = column.to_s.gsub(/\_id\z/, '')
              next unless fixture_id = attributes[reflection]
              if attrs = data[foreign_model.table_name][fixture_id]
                attributes[column.to_s] = attrs['id']
              else
                raise "Cannot find #{fixture_id} for #{references} in #{table}##{record}"
              end
              attributes.delete(reflection)
            end
          else
            # Polymorphic reflection case
            data[table.to_s].each do |record, attributes|
              reflection = column.to_s.gsub(/\_id\z/, '')
              next unless attributes[reflection]
              type_column = reflection + '_type'
              fixture_id, class_name = attributes[reflection].split(/[\(\)\s]+/)[0..1]
              foreign_model = class_name.constantize
              if attrs = data[foreign_model.table_name][fixture_id]
                attributes[column.to_s] = attrs['id']
                attributes[type_column] = foreign_model.name
              else
                raise "Cannot find #{fixture_id} for #{references} in #{table}##{record}"
              end
              attributes.delete(reflection)
            end
          end
        end
        data[table.to_s].each do |record, attributes|
          data[table.to_s][record] = attributes.sort_by(&:first).each_with_object({}) do |pair, hash|
            hash[pair.first] = pair.second
            hash
          end
        end
      end

      # Write
      Ekylibre::Schema.tables.each do |table, _columns|
        File.open(directory.join("#{table}.yml"), 'wb') do |f|
          f.write data[table].to_yaml
        end
      end

      # Clean
      Clean::Annotations.run(only: :fixtures, verbose: false)
    end

    # Reverse of #columnize_keys
    # Fixtures are expected with ids !
    def reflectionize_keys
      # Load and prepare fixtures
      data = {}
      model_ids = {}
      Ekylibre::Schema.tables.each do |table, _columns|
        records = YAML.load_file(directory.join("#{table}.yml"))
        base_model = table.to_s.classify
        counter = {}
        data[table.to_s] = records.values.sort { |a, b| [a['type'] || base_model, a['id']] <=> [b['type'] || base_model, b['id']] }.each_with_object({}) do |attributes, hash|
          model = attributes['type'] ? attributes['type'].underscore.pluralize : table.to_s
          counter[model] ||= 0
          counter[model] += 1
          hash["#{model}_#{counter[model].to_s.rjust(3, '0')}"] = attributes
          hash
        end
      end

      # Convert
      Ekylibre::Schema.tables.each do |table, columns|
        columns.each do |column, definition|
          next unless references = definition[:references]
          if references.is_a?(Symbol)
            # Standard reflection case
            foreign_model = references.to_s.camelcase.constantize
            puts references.inspect.red unless data[foreign_model.table_name]
            data[table.to_s].each do |record, attributes|
              next unless fixture_id = attributes[column.to_s]
              if attrs = data[foreign_model.table_name].detect { |_r, a| a['id'] == fixture_id }
                attributes[column.to_s.gsub(/\_id\z/, '')] = attrs.first
              else
                raise "Cannot find #{foreign_model.name} #{fixture_id} for #{column} in #{table}##{record}"
              end
              attributes.delete(column.to_s)
            end
          else
            # Polymorphic reflection case
            data[table.to_s].each do |record, attributes|
              type_column = column.to_s.gsub(/\_id\z/, '') + '_type'
              next unless (fixture_id = attributes[column.to_s]) && (fixture_type = attributes[type_column])
              foreign_model = fixture_type.constantize
              if attrs = data[foreign_model.table_name].detect { |_r, a| a['id'] == fixture_id && (a['type'] || foreign_model.name) == fixture_type }
                attributes[column.to_s.gsub(/\_id\z/, '')] = "#{attrs.first} (#{fixture_type})"
              else
                raise "Cannot find #{fixture_type}##{fixture_id} for #{column} in #{table}##{record} (#{attributes['id']})"
              end
              attributes.delete(column.to_s)
              attributes.delete(type_column)
            end
          end
        end
      end

      data.each do |table, records|
        records.each do |record, attributes|
          data[table][record] = attributes.delete_if { |k, _v| k == 'id' }.sort_by(&:first).each_with_object({}) do |pair, hash|
            hash[pair.first] = pair.second
            hash
          end
        end
      end

      # Write
      Ekylibre::Schema.tables.each do |table, _columns|
        File.open(directory.join("#{table}.yml"), 'wb') do |f|
          f.write data[table].to_yaml
        end
      end

      # Clean
      Clean::Annotations.run(only: :fixtures, verbose: false)
    end

    # Adds model conform fixture ids
    # In STI, fixture name are rewritten with name of model
    # Example: product_153 will become plant_009
    def beautify_fixture_ids(options = {})
      path = options[:path] || directory
      # Load and prepare fixtures
      data = {}
      model_ids = {}
      Ekylibre::Schema.tables.each do |table, _columns|
        records = YAML.load_file(path.join("#{table}.yml"))
        base_model = table.to_s.classify
        counter = {}
        data[table.to_s] = records.values.sort { |a, b| [a['type'] || base_model, a['id']] <=> [b['type'] || base_model, b['id']] }.each_with_object({}) do |attributes, hash|
          model = attributes['type'] ? attributes['type'].underscore.pluralize : table.to_s
          counter[model] ||= 0
          counter[model] += 1
          hash["#{model}_#{counter[model].to_s.rjust(3, '0')}"] = attributes
          hash
        end
      end

      data.each do |table, records|
        records.each do |record, attributes|
          data[table][record] = attributes.sort_by(&:first).each_with_object({}) do |pair, hash|
            hash[pair.first] = pair.second
            hash
          end
        end
      end

      # Write
      Ekylibre::Schema.tables.each do |table, _columns|
        File.open(path.join("#{table}.yml"), 'wb') do |f|
          f.write data[table].to_yaml
        end
      end
    end

    def yaml_escape(value, type = :string)
      value = value.to_s
      value = if type == :float || type == :decimal || type == :integer
                value
              elsif type == :boolean
                (%w(1 t T true yes TRUE).include?(value) ? 'true' : 'false')
              else
                value.to_yaml.gsub(/^\-\-\-\s*/, '').strip
              end
      value
    end

    def convert_value(value, type = :string)
      value = value.to_s
      value = if type == :float
                value.to_f
              elsif type == :geometry || type == :point || type == :multi_polygon
                Charta.new_geometry(value).to_ewkt
              elsif type == :decimal
                value.to_f
              elsif type == :integer
                value.to_i
              elsif type == :date
                value.to_date
              elsif type == :datetime
                value.to_time(:utc)
              elsif type == :boolean
                (%w(1 t T true yes TRUE).include?(value) ? true : false)
              elsif type == :json || type == :jsonb
                JSON.parse(value)
              else
                puts "Unknown type to parse in fixtures: #{type.inspect}".red unless [:text, :string, :uuid].include?(type)
                value =~ /\A\-\-\-(\s+|\z)/ ? YAML.load(value) : value
              end
      value
    end
  end
end
