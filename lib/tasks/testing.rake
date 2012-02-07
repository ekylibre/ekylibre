
Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

def remove_task(task_name)
  Rake.application.remove_task(task_name)
end

namespace :test do

  desc "Run tests for lib sources"
  Rake::TestTask.new(:lib) do |t|    
    t.libs << "test"
    t.pattern = 'test/lib/**/*_test.rb'
    t.verbose = true    
  end

  remove_task("run")

  task :run => %w(test:units test:functionals test:integration test:lib)
end

# # lib_task = Rake::Task["test:lib"]
# # test_task = Rake::Task[:test]
# # test_task.enhance { lib_task.invoke }
# remove_task("test")

# task :test do
#   errors = %w(test:units test:functionals test:integration test:lib).collect do |task|
#     begin
#       Rake::Task[task].invoke
#       nil
#     rescue => e
#       task
#     end
#   end.compact
#   abort "Errors running #{errors * ', '}!" if errors.any?
# end


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


  desc "Load fixtures files in development database (removing existing data)"
  task :load=>:environment do
    # ActiveRecord::Base.establish_connection(:development)
    # ActiveRecord::Base.configurations[:fixtures_load_order]
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:schema:load"].invoke
    tables = Ekylibre.models.collect{|t| t.to_s.pluralize}
    require 'active_record/fixtures'
    # ActiveRecord::
    Fixtures.create_fixtures(fixtures_dir, tables)
  end

  desc "Write development database in fixtures files (removing existing files)"
  task :write=>:environment do
    # ActiveRecord::Base.establish_connection(:development)
    tables = Ekylibre.models.collect{|t| t.to_s.pluralize}
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
