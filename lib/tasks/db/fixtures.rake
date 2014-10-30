namespace :db do
  namespace :fixtures do

    fixtures_dir = Rails.root.join("test", "fixtures")

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
              elsif type == :decimal
                value.to_d
              elsif type == :integer
                value.to_i
              elsif type == :boolean
                (['1', 't', 'T', 'true', 'yes', 'TRUE'].include?(value) ? true : false)
              else
                value
              end
      return value
    end


    # desc "Load fixtures files in development database (removing existing data)"
    # task :load => :environment do
    #   # ActiveRecord::Base.establish_connection(:development)
    #   # ActiveRecord::Base.configurations[:fixtures_load_order]
    #   Rake::Task["db:drop"].invoke
    #   Rake::Task["db:create"].invoke
    #   Rake::Task["db:schema:load"].invoke
    #   tables = Ekylibre::Schema.table_names
    #   require 'active_record/fixtures'
    #   ActiveRecord::FixtureSet.create_fixtures(fixtures_dir, tables)
    # end

    desc "Write development database in fixtures files (removing existing files)"
    task :write => :environment do
      # ActiveRecord::Base.establish_connection(:development)
      tables = Ekylibre::Schema.table_names
      for table in tables
        File.open(fixtures_dir.join("#{table}.yml"), "wb") do |f|
          columns = {}
          for column in table.to_s.classify.constantize.columns
            columns[column.name.to_s] = column.type
          end
          data = {}
          for row in ActiveRecord::Base.connection.select_all("SELECT * FROM #{table} ORDER BY id")
            key = "#{table}_#{row['id'].rjust(3, '0')}"
            # f.write("#{key}:\n")
            data[key] = {}
            for attribute, value in row.sort
              data[key][attribute] = convert_value(value, columns[attribute]) unless value.nil?
              # f.write("  #{attribute}: #{yaml_escape(value, columns[attribute])}\n") unless value.nil?
            end
          end
          f.write data.to_yaml
        end
      end
    end

  end
end
