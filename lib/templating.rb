require 'templating/writer'
require 'templating/compilers'

# Aims to be the reports manager/compiler
# Supports only XIL format for now
module Templating

  VERSION = '2.0'

  def self.fonts_dir
    Pathname.new(File.dirname(__FILE__)).join("templating", "data", "fonts")
  end

  # Preamble permits to know which version of Templating
  # generates the code. This preamble is written at the start of each compiled report
  def self.preamble
    "# version: #{Ekylibre.version}/#{VERSION}\n"
  end

  # Main method to compile a report in Ruby code
  def self.compile(string, format, options={})
    compiler = format.to_s.camelcase
    if Templating::Compilers.const_defined?(compiler)
      mod = Templating::Compilers.const_get(compiler)
      return self.preamble + mod.compile(string, options)
    else
      raise ArgumentError.new("Unsupported format of template: #{format}")
    end
  end
  
end

