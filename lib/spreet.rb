require 'fastercsv'
require 'spreadsheet'



# Abstract SpreadSheet
class Spreet

  @@formats = {}

  def open(file, format)
    unless @klass = @@formats[format.to_sym]
      raise ArgumentError.new("Unknown format #{format.inspect} (accepts only #{@@formats.to_sentence})")
    end
  end

  def sheets
    @klass.sheets
  end

  def rows(sheet=0, &block)
  end

  protected
  
  def self.register(code, klass)
    code = code.to_s
    raise ArgumentError.new("Unvalid code for Spreet engine") unless code.size > 0
    @@formats[code.to_sym] = klass
  end

end


    
