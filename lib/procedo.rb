# require 'procedo/xml'
# require 'procedo/errors'

# Procedo module aims to manage procedure which permits to define way of work
# simply.
module Procedo
  XML_NAMESPACE = 'http://www.ekylibre.org/XML/2013/procedures'.freeze

  # autoload :Procedure,           'procedo/procedure'
  # autoload :Handler,             'procedo/handler'
  # autoload :Converter,           'procedo/converter'
  # autoload :Compilers,           'procedo/compilers'
  # autoload :CompiledProcedure,   'procedo/compiled_procedure'
  # autoload :CompiledVariable,    'procedo/compiled_variable'
  # autoload :Formula,             'procedo/formula'

  # Namespace used to "store" compiled procedures
  module CompiledProcedures
  end

  class Error < StandardError
  end

  @@list = HashWithIndifferentAccess.new

  class << self
    def procedures
      @@list.values
    end

    # Returns the names of the procedures
    def procedure_names
      @@list.keys
    end

    # Returns an array of couple human_name/name sorted by human name.
    def selection
      procedures.map { |p| [p.human_name, p.name.to_s] }.sort { |a, b| I18n.transliterate(a.first) <=> I18n.transliterate(b.first) }
    end

    # Give access to named procedures
    def find(name)
      @@list[name]
    end
    alias [] find

    # Browse all available procedures
    def each_procedure
      @@list.each do |_, procedure|
        yield procedure
      end
    end

    # Browse all parameters of all procedures
    def each_parameter
      each_procedure do |procedure|
        procedure.parameters.each do |parameter|
          yield parameter
        end
      end
    end

    # Browse all parameters of all procedures
    def each_product_parameter
      each_procedure do |procedure|
        procedure.product_parameters.each do |parameter|
          yield parameter
        end
      end
    end

    def each_variable(&block)
      ActiveSupport::Deprecation.warn 'Procedo::each_variable is deprecated. Please use Procedo::each_parameter instead.'
      each_parameter(&block)
    end

    # Load all files
    def load
      # Inventory procedures
      Dir.glob(root.join('*.xml')).sort.each do |path|
        Procedo::XML.parse(path).each do |procedure|
          @@list[procedure.name] = procedure
        end
      end
      true
    end

    # Returns the root of the procedures
    def root
      Rails.root.join('config', 'procedures')
    end
  end
end

Procedo.load
Rails.logger.info 'Loaded procedures: ' + Procedo.procedure_names.to_sentence
