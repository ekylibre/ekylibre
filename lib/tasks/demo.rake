# -*- coding: utf-8 -*-
module Ekylibre
  DEMOS = [:general_ledger, :buildings, :animals, :land_parcels, :sales, :deliveries, :productions]


  class FixtureCountExceeded < StandardError
  end

  class Fixturize
    def initialize(max)
      @count = 0
      @max = max
    end

    def check_point
      @count += 1
      print "."
      raise FixtureCountExceeded.new if @count >= @max
    end
  end

  def self.fixturize(name, options = {}, &block)
    STDOUT.sync = true
    max = ENV["max"].to_i
    max = 1_000_000 if max.zero?
    f = Fixturize.new(max)
    start = Time.now
    ActiveRecord::Base.transaction do
      print "#{name.to_s.rjust(32)}: "
      begin
        yield(f)
      rescue FixtureCountExceeded => e
        print "! "
      end
    end
    puts "#{(Time.now - start).round(2).to_s.rjust(8)}s"
  end

end

require 'ostruct'
require 'pathname'

# Build a task with a transaction
def demo(name, &block)
  task(name) do
    ActiveRecord::Base.transaction(&block)
  end
end

namespace :db do
  task :demo => :demo
end

desc "Build demo data"
namespace :demo do
  for demo in Ekylibre::DEMOS
    require Pathname.new(__FILE__).dirname.join("demo", demo.to_s).to_s
  end
end

desc "Create demo data -- also available " + Ekylibre::DEMOS.collect{|c| "demo:#{c}"}.join(", ")
task :demo => :environment do
  ActiveRecord::Base.transaction do
    for demo in Ekylibre::DEMOS
      Rake::Task["demo:#{demo}"].invoke
    end
  end
end

