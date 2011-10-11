
module Exchanges

  class NotSupportedFormatError < StandardError
  end

  class NotWellFormedFileError < ArgumentError
  end

  class ImcompatibleDataError < ArgumentError
  end

  class Exchanger
    def self.import(*args)
      raise NotImplementedError.new
    end
    def self.export(*args)
      raise NotImplementedError.new
    end
  end

  def self.import(company, format, file, options={})
    ActiveRecord::Base.transaction do
      if format == :ebp_edi
        Exchanges::EbpEdi.import(company, file, options)
      elsif format == :isa_compta
        Exchanges::IsaCompta.import(company, file, options)
      else
        raise NotSupportedFormat.new("Format #{format.inspect} is not supported for import")
      end
    end
  end


  def self.export(company, format, file, options={})
    raise NotSupportedFormat.new("Format #{format.inspect} is not supported for import")    
  end


end

require File.join(File.dirname(__FILE__), 'exchanges', 'ebp_edi')
require File.join(File.dirname(__FILE__), 'exchanges', 'isa_compta')
