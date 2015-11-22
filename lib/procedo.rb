module Procedo
  XML_NAMESPACE       = 'http://www.ekylibre.org/XML/2013/procedures'.freeze
  DEFAULT_NAMESPACE   = :base
  NAMESPACE_SEPARATOR = '-'
  VERSION_SEPARATOR   = NAMESPACE_SEPARATOR

  autoload :Error,               'procedo/errors'
  autoload :Errors,              'procedo/errors'
  autoload :Procedure,           'procedo/procedure'
  autoload :Variable,            'procedo/variable'
  autoload :Handler,             'procedo/handler'
  autoload :Converter,           'procedo/converter'
  autoload :HandlerMethodParser, 'procedo/handler_method'
  autoload :Compilers,           'procedo/compilers'
  autoload :CompiledProcedure,   'procedo/compiled_procedure'
  autoload :CompiledVariable,    'procedo/compiled_variable'
  autoload :FormulaFunctions,    'procedo/formula_functions'

  # Namespace used to "store" compiled procedures
  module CompiledProcedures
  end

  @@list = HashWithIndifferentAccess.new

  class << self

    def procedures
      @@list.values
    end

    # def list
    #   @@list
    # end

    # Returns the names of the procedures
    def procedure_names
      @@list.keys
    end

    # Give access to named procedures
    def find(name)
      @@list[name]
    end
    alias :[] :find

    # Returns direct procedures of nature
    def procedures_of_nature(*natures)
      fail "No more usable"
      procedures.select do |p|
        p.of_nature?(*natures)
      end
    end

    # Returns direct procedures of nature
    def procedures_of_activity_family(*families)
      procedures.select do |p|
        p.of_activity_family?(*families)
      end.uniq
    end

    # Returns procedures of nature and sub natures
    def procedures_of_nature_and_its_children(nature, options = {})
      procedures_of_nature(*Nomen::ProcedureNature.all(nature).map(&:to_sym), options)
    end

    def each_procedure
      @@list.each do |_, procedure|
        yield procedure
      end
    end

    def each_variable
      each_procedure do |procedure|
        procedure.variables.each do |_, variable|
          yield variable
        end
      end
    end

    # Load all files
    def load
      # Inventory procedures
      Dir.glob(root.join('*.xml')).sort.each do |path|
        f = File.open(path, 'rb')
        document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
        # Add a better syntax check
        if document.root.namespace.href.to_s == XML_NAMESPACE
          document.root.xpath('xmlns:procedure').each do |element|
            procedure = Procedure.new(element)
            @@list[procedure.name] = procedure
          end
        else
          Rails.logger.info("File #{path} is not a procedure as defined by #{XML_NAMESPACE}")
        end
      end
      true
    end

    # Returns the root of the procedures
    def root
      Rails.root.join('config', 'procedures-2')
    end
  end
end

Procedo.load
Rails.logger.info 'Loaded procedures: ' + Procedo.procedure_names.to_sentence
