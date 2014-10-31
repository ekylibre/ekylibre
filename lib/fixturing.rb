require 'active_record/fixtures'

module Fixturing
  class << self

    def current_version
      CSV.read(migrations_file).last.first.to_i
    end

    def directory
      Rails.root.join("test", "fixtures")
    end

    def migrations_file
      directory.join(migrations_table)
    end

    def migrations_table
      "schema_migrations"
    end

    def up_to_date?
      current_version == ActiveRecord::Migrator.current_version
    end

    def restore(tenant)
      Ekylibre::Tenant.check!(tenant)
      if Ekylibre::Tenant.exist?(tenant)
        Ekylibre::Tenant.drop(tenant)
      end
      # Apartment.connection.execute(%{CREATE SCHEMA "#{tenant}"})
      Ekylibre::Tenant.create(tenant)
      Ekylibre::Tenant.migrate(tenant, to: current_version)
      columnize_keys # Simple IDs
      Ekylibre::Tenant.switch(tenant)
      ActiveRecord::FixtureSet.create_fixtures(directory, Ekylibre::Schema.table_names)
      reflectionize_keys # Back to simple reading
      unless up_to_date?
        migrate
      end
    end

    # Dump data of database into fixtures
    def dump(tenant = nil)
      Ekylibre::Tenant.switch(tenant) if tenant

      migrate unless up_to_date?

      # ActiveRecord::Base.establish_connection(:development)
      Ekylibre::Schema.tables.each do |table, columns|
        records = {}
        for row in ActiveRecord::Base.connection.select_all("SELECT * FROM #{table} ORDER BY id")
          record = {}
          for attribute, value in row.sort
            if columns[attribute]
              unless value.nil?
                record[attribute] = convert_value(value, columns[attribute][:type].to_sym)
              end
            else
              puts attribute.red
            end
          end
          records["#{table}_#{row['id'].rjust(3, '0')}"] = record
        end

        File.open(directory.join("#{table}.yml"), "wb") do |f|
          f.write records.to_yaml
        end
      end

      # Dump last schema_migrations into schema_migrations file
      File.open(migrations_file, "wb") do |f|
        f.write ActiveRecord::Base.connection.select_value("SELECT * FROM #{migrations_table} ORDER BY 1 DESC")
      end

      # Clean fixtures
      reflectionize_keys
    end


    def migrate(tenant)
      puts "Migrate fixture from " + current_version.inspect.red +
        " to " + ActiveRecord::Migrator.current_version.inspect.green
      Ekylibre::Tenant.migrate(tenant, to: ActiveRecord::Migrator.current_version)
    end


    # Convert reflection to hard representation in fixtures
    #   my_thing: things_001             => my_thing_id: 1
    #   my_polymorph: things_001 (Thing) => my_polymorph_id: 1
    #                                       my_polymorph_type: Thing
    def columnize_keys
      # Load and prepare fixtures
      data = {}
      Ekylibre::Schema.tables.each do |table, columns|
        records = YAML.load_file(directory.join("#{table}.yml"))
        ids = records.values.collect{|a| a["id"]}.compact.map(&:to_i)
        records.each do |record, attributes|
          unless attributes["id"]
            id = record.split("_").last.to_i
            attributes["id"] = ids.include?(id) ? (1..(ids.max + 10)).to_a.detect{|x| !ids.include?(x) } : id
            ids << attributes["id"]
          end
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
                attributes[column.to_s] = attrs["id"]
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
              type_column = reflection + "_type"
              fixture_id, class_name = attributes[reflection].split(/[\(\)\s]+/)[0..1]
              foreign_model = class_name.constantize
              if attrs = data[foreign_model.table_name][fixture_id]
                attributes[column.to_s] = attrs["id"]
                attributes[type_column] = foreign_model.name
              else
                raise "Cannot find #{fixture_id} for #{references} in #{table}##{record}"
              end
              attributes.delete(reflection)
            end
          end
        end
        data[table.to_s].each do |record, attributes|
          data[table.to_s][record] = attributes.sort{|a,b| a.first <=> b.first }.inject({}) do |hash, pair|
            hash[pair.first] = pair.second
            hash
          end
        end
      end

      # Write
      Ekylibre::Schema.tables.each do |table, columns|
        File.open(directory.join("#{table}.yml"), "wb") do |f|
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
      Ekylibre::Schema.tables.each do |table, columns|
        records = YAML.load_file(directory.join("#{table}.yml"))
        base_model = table.to_s.classify
        counter = {}
        data[table.to_s] = records.values.sort{|a,b| [a["type"] || base_model, a["id"]] <=> [b["type"] || base_model, b["id"]] }.inject({}) do |hash, attributes|
          model = attributes["type"] ? attributes["type"].underscore.pluralize : table.to_s
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
              if attrs = data[foreign_model.table_name].detect{|r, a| a["id"] == fixture_id}
                attributes[column.to_s.gsub(/\_id\z/, '')] = attrs.first
              else
                raise "Cannot find #{fixture_id} for #{references} in #{table}##{record}"
              end
              attributes.delete(column.to_s)
            end
          else
            # Polymorphic reflection case
            data[table.to_s].each do |record, attributes|
              type_column = column.to_s.gsub(/\_id\z/, '') + "_type"
              next unless fixture_id = attributes[column.to_s] and fixture_type = attributes[type_column]
              foreign_model = fixture_type.constantize
              if attrs = data[foreign_model.table_name].detect{|r,a| a["id"] == fixture_id and (a["type"] || foreign_model.name) == fixture_type}
                attributes[column.to_s.gsub(/\_id\z/, '')] = "#{attrs.first} (#{fixture_type})"
              else
                raise "Cannot find #{fixture_type}##{fixture_id} for #{references} in #{table}##{record}"
              end
              attributes.delete(column.to_s)
              attributes.delete(type_column)
            end
          end
        end
      end

      data.each do |table, records|
        records.each do |record, attributes|
          data[table][record] = attributes.delete_if{|k,v| k == "id" }.sort{|a,b| a.first <=> b.first }.inject({}) do |hash, pair|
            hash[pair.first] = pair.second
            hash
          end
        end
      end

      # Write
      Ekylibre::Schema.tables.each do |table, columns|
        File.open(directory.join("#{table}.yml"), "wb") do |f|
          f.write data[table].to_yaml
        end
      end

      # Clean
      Clean::Annotations.run(only: :fixtures, verbose: false)
    end


    def yaml_escape(value, type = :string)
      value = value.to_s
      value = if type == :float or type == :decimal or type == :integer
                value
              elsif type == :boolean
                (['1', 't', 'T', 'true', 'yes', 'TRUE'].include?(value) ? 'true' : 'false')
              else
                value.to_yaml.gsub(/^\-\-\-\s*/, '').strip
              end
      return value
    end

    def convert_value(value, type = :string)
      value = value.to_s
      value = if type == :float
                value.to_f
              elsif type == :spatial
                Charta::Geometry.new(value).to_ewkt
              elsif type == :decimal
                value.to_f
              elsif type == :integer
                value.to_i
              elsif type == :date
                value.to_date
              elsif type == :datetime
                value.to_time
              elsif type == :boolean
                (['1', 't', 'T', 'true', 'yes', 'TRUE'].include?(value) ? true : false)
              else
                value =~ /\A\-\-\-(\s+|\z)/ ? YAML.load(value) : value
              end
      return value
    end

  end
end
