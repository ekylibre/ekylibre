# encoding: UTF-8
module Exchanges

  @@exporters = {}
  @@importers = {}

  class NotSupportedFormatError < StandardError
  end

  class NotWellFormedFileError < ArgumentError
  end

  class ImcompatibleDataError < ArgumentError
  end

  def self.add_exporter(nature, &block)
    unless Nomen::ExchangeNatures[nature]
      raise "Unknown exchange nature: #{nature}"
    end
    @@exporters[nature.to_sym] = block
  end

  def self.add_importer(nature, &block)
    unless Nomen::ExchangeNatures[nature]
      raise "Unknown exchange nature: #{nature}"
    end
    @@importers[nature.to_sym] = block
  end

  class << self

    def import(nature, file)
      unless @@importers[nature]
        raise "Unable to find importer #{nature}"
      end
      @@importers[nature].call(file)
      # ActiveRecord::Base.transaction do
      #   if format == :ebp_edi
      #     Exchanges::EbpEdi.import(company, file, options)
      #   elsif format == :isa_compta
      #     Exchanges::IsaCompta.import(company, file, options)
      #   else
      #     raise NotSupportedFormat.new("Format #{format.inspect} is not supported for import")
      #   end
      # end
    end


    def export(company, format, file, options={})
      raise NotSupportedFormat.new("Format #{format.inspect} is not supported for import")
    end

  end


  class Exchanger
    @@verbose = false

    def self.import(*args)
      raise NotImplementedError.new
    end
    def self.export(*args)
      raise NotImplementedError.new
    end

    def self.benchmark(text, &block)
      if @@verbose
        STDOUT.sync = true
        @@depth ||= -1
        @@depth += 1
        prefix = "| " * @@depth
        puts(prefix + "/ " + text)
        start = Time.now
        yield
        duration = (Time.now - start).to_f
        minutes = (duration/60).to_i
        seconds = (duration - 60*minutes.to_f)
        puts(prefix + "\\ #{minutes.to_s.rjust(2, '0')}:#{seconds}")
        @@depth -= 1
      else
        yield
      end
    end

    def self.print_jauge(count, total_count, options={})
      status = ["#{(100*count.to_f/total_count).to_i.to_s.rjust(3)}% [", '', "]"]
      if options[:start]
        stop = options[:stop]||Time.now
        if options[:time] == :elapsed
          duration = (stop - options[:start]).to_f
          minutes = (duration/60).to_i
          seconds = (duration - 60*minutes).to_i
          status[2] += " #{minutes}m#{seconds.to_s.rjust(2,'0')}s "
        else
          duration = (stop - options[:start]).to_f * (total_count - count) / count
          minutes = (duration/60).to_i
          seconds = (duration - 60*minutes).to_i
          status[2] += " rem. #{minutes}m#{seconds.to_s.rjust(2,'0')}s "
        end
      end
      size = `stty size`.split[1].to_i - status.join.length - 1
      done = (size*count.to_f/total_count).to_i
      status[1] = "="*done + ">" + " "*(size - done)
      status = status.join
      if options[:replace]
        print("\r"*options[:replace].size + status)
        puts "" if options[:new_line]
      else
        puts status
      end
      return status
    end

  end


end

require File.join(File.dirname(__FILE__), 'exchanges', 'ebp_edi')
require File.join(File.dirname(__FILE__), 'exchanges', 'isa_compta')
