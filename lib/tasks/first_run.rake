# -*- coding: utf-8 -*-
module Ekylibre
  LOADERS = [:base, :general_ledger, :entities, :buildings, :products, :animals, :land_parcels, :productions, :analyses, :sales, :deliveries, :interventions, :guides]
  LOADERS_OPERATIONS = [:base, :buildings, :products, :land_parcels, :productions, :deliveries, :interventions]

  MAX = -1

  class CountExceeded < StandardError
  end

  class Counter
    attr_reader :count

    def initialize(max = -1)
      @count = 0
      @max = max
    end

    def check_point(increment = 1)
      @count += increment
      print "." if (@count - increment).to_i != @count.to_i
      if @max > 0
        raise CountExceeded.new if @count >= @max
      end
    end
  end

  class Loader
    attr_reader :folder

    def initialize(folder, options = {})
      @folder = folder.to_s
      @folder_path = Ekylibre::FirstRun.path.join(@folder)
      @max = (options[:max] || ENV["max"]).to_i
      @max = MAX if @max.zero?
      @records = {}.with_indifferent_access
    end

    def manifest
      unless @manifest
        file = path("manifest.yml")
        @manifest = (file.exist? ? YAML.load_file(file).deep_symbolize_keys : {})
        @manifest[:company] ||= {}
      end
      return @manifest
    end

    def can_load?(key)
      !@manifest[key].is_a?(FalseClass)
    end

    def can_load_default?(key)
      can_load?(key) and !@manifest[key].is_a?(Hash)
    end

    def create_from_manifest(records, *args)
      options = args.extract_options!
      main_column = args.shift || :name
      model = records.to_s.classify.constantize
      if data = @manifest[records]
        @records[records] ||= {}.with_indifferent_access
        unless data.is_a?(Hash)
          raise "Cannot load #{records}: Hash expected, got #{records.class.name} (#{records.inspect})"
        end
        for identifier, attributes in data
          attributes = attributes.with_indifferent_access
          attributes[main_column] = identifier.to_s
          for reflection in model.reflections.values
            if attributes[reflection.name] and not attributes[reflection.name].class < ActiveRecord::Base
              attributes[reflection.name] = get(reflection.class_name.tableize, attributes[reflection.name].to_s)
            end
          end
          @records[records][identifier] = model.create!(attributes)
        end
      end
    end

    # Returns the record corresponding to the identifier
    def get(records, identifier)
      if @records[records]
        return @records[records][identifier]
      end
      return nil
    end


    def path(*args)
      return @folder_path.join(*args)
    end

    def count(name, options = {}, &block)
      STDOUT.sync = true
      f = Counter.new(@max)
      start = Time.now
      label_size = options[:label_size] || 20
      label = name.to_s.humanize.rjust(label_size)
      ellipsis = "…"
      if label.size > label_size
        first = ((label_size - ellipsis.size).to_f / 2).round
        label = label[0..(first-1)] + ellipsis + label[-(label_size - first - ellipsis.size)..-1]
        # label = "..." + label[(-label_size + 3)..-1]
      end
      # ActiveRecord::Base.transaction do
      print "[#{@folder.green}] #{label.blue}: "
      begin
        yield(f)
        print " " * (@max - f.count) if @max != MAX and f.count < @max
        print "  "
      rescue CountExceeded => e
        print "! "
      end
      # end
      puts "#{(Time.now - start).round(2).to_s.rjust(6)}s"
    end

  end

end

require 'ostruct'
require 'pathname'

# Build a task with a transaction
def load_data(name, &block)
  task(name => :environment) do
    folder = ENV["folder"]
    folder = "default" if Ekylibre::FirstRun.path.join("default").exist?
    folder ||= "demo"
    ActiveRecord::Base.transaction do
      yield Ekylibre::Loader.new(folder)
    end
  end
end

# # Build a task with a transaction
# def demo(name, &block)
#   task(name => :environment) do
#     ActiveRecord::Base.transaction(&block)
#   end
# end

# namespace :db do
#   task :first_run do
#     Rake::Task["first_run"].invoke
#   end
# end

namespace :first_run do
  for loader in Ekylibre::LOADERS
    require Pathname.new(__FILE__).dirname.join("first_run", loader.to_s).to_s
  end

  desc "Create first_run data for interventions/operations purpose only"
  task :operations => :environment do
    ActiveRecord::Base.transaction do
      for loader in Ekylibre::LOADERS_OPERATIONS
        Rake::Task["first_run:#{loader}"].invoke
      end
    end
  end

end

desc "Create first_run data -- also available " + Ekylibre::LOADERS.collect{|c| "first_run:#{c}"}.join(", ")
task :first_run => :environment do
  ActiveRecord::Base.transaction do
    for loader in Ekylibre::LOADERS
      Rake::Task["first_run:#{loader}"].invoke
    end
  end
end

namespace :first_runs do

  Ekylibre::LOADERS.each_with_index do |loader, index|
    loaders = Ekylibre::LOADERS[index..-1]
    code  = "desc 'Execute #{loaders.to_sentence}'\n"
    code << "task :#{loader} do\n"
    for d in loaders
      code << "  puts 'Load #{d.to_s.red}'\n"
      code << "  Rake::Task['first_run:#{d}'].invoke\n"
    end
    code << "end"
    eval code
  end

end


desc "Create first_run data independently -- also available " + Ekylibre::LOADERS.collect{|c| "first_run:#{c}"}.join(", ")
task :first_runs => :environment do
  for loader in Ekylibre::LOADERS
    puts "Load #{loader.to_s.red}"
    Rake::Task["first_run:#{loader}"].invoke
  end
end


