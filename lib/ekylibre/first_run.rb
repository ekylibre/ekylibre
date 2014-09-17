require 'zip'

module Ekylibre
  module FirstRun

    autoload :Counter, 'ekylibre/first_run/counter'
    autoload :Booker,  'ekylibre/first_run/booker'
    autoload :Base,    'ekylibre/first_run/base'

    def self.launch(options = {})
      Base.new(options).launch
    end

    def self.build(folder)
      raise NotImplementedError
    end

    def self.path
      Rails.root.join("db", "first_runs")
    end

    def self.add_loader(name, &block)
      @@loaders ||= {}
      @@loaders[name.to_sym] = block
    end

    def self.loaders
      @@loaders.keys
    end

    def self.call_loader(name, base)
      unless base.is_a?(Ekylibre::FirstRun::Base)
        raise "Invalid first run. Need a Ekylibre::FirstRun::Base"
      end
      @@loaders[name].call(base)
    end

  end
end

require 'ekylibre/first_run/loaders'
