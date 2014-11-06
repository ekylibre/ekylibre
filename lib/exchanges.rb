# encoding: UTF-8
module Exchanges

  @@exporters = {}.with_indifferent_access
  @@importers = {}.with_indifferent_access

  class Error < ::StandardError
  end

  class NotSupportedFormatError < Error
  end

  class NotWellFormedFileError < Error
  end

  class IncompatibleDataError < Error
  end

  autoload :Exchange, 'exchanges/exchange'

  class << self

    def add_importer(nature, &block)
      unless Nomen::ExchangeNatures[nature]
        raise "Unknown exchange nature: #{nature}"
      end
      @@importers[nature] = block
    end

    def importers
      @@importers.keys
    end

    def import(nature, file, &block)
      unless proc = @@importers[nature]
        raise "Unable to find importer #{nature.inspect}"
      end
      execute(proc, file, &block)
    end

    def add_exporter(nature, &block)
      unless Nomen::ExchangeNatures[nature]
        raise "Unknown exchange nature: #{nature}"
      end
      @@exporters[nature] = block
    end

    def exporters
      @@exporters.keys
    end

    def export(nature, file, options={}, &block)
      unless proc = @@exporters[nature]
        raise "Unable to find exporter #{nature.inspect}"
      end
      execute(proc, file, options, &block)
    end

    def execute(callable, *args, &block)
      exchange = Exchange.new(&block)
      callable.call(*args, exchange)
      GC.start
    end

  end

end

require_relative 'exchanges/exchangers'
