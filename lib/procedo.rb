module Procedo
  class MissingAttribute < StandardError
  end

  class MissingVariable < StandardError
  end

  class MissingProcedure < StandardError
  end

  class MissingRole < StandardError
  end

  class NotUniqueIdentifier < StandardError
  end

  class UnknownProcedureNature < StandardError
  end

  class UnknownRole < StandardError
  end

  class InvalidExpression < StandardError
  end

  class AmbiguousExpression < InvalidExpression
  end

  XMLNS = "http://www.ekylibre.org/XML/2013/procedures".freeze
  NS_SEPARATOR = "-"

  autoload :Procedure,           'procedo/procedure'
  autoload :Variable,            'procedo/variable'
  autoload :Handler,             'procedo/handler'
  # autoload :HandlerMethod,       'procedo/handler_method'
  autoload :HandlerMethodParser, 'procedo/handler_method'
  autoload :Operation,           'procedo/operation'
  autoload :Task,                'procedo/task'
  autoload :Indicator,           'procedo/indicator'
  autoload :Action,              'procedo/action'

  @@list = HashWithIndifferentAccess.new

  class << self

    def list(options = {})
      l = @@list
      l = l.select{|k,v| !v.system? } unless options[:with_system]
      return l
    end


    # Returns the names of the procedures
    def procedures(options = {})
      return list(options).keys
    end
    alias :names :procedures

    # Give access to named procedures
    def [](name)
      @@list[name]
    end

    # Returns direct procedures of nature
    def procedures_of_nature(*natures)
      options = natures.extract_options!
      list(options).values.select do |p|
        p.of_nature?(*natures)
      end
    end

    # Returns procedures of nature and sub natures
    def procedures_of_nature_and_its_children(nature, options = {})
      procedures_of_nature(*Nomen::ProcedureNatures.all(nature).map(&:to_sym), options = {})
    end

    # Load all files
    def load
      # Inventory procedures
      for path in Dir.glob(root.join("*.xml")).sort
        f = File.open(path, "rb")
        document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
        # Add a better syntax check
        if document.root.namespace.href.to_s == XMLNS
          document.root.xpath('xmlns:procedure').each do |element|
            procedure = Procedure.new(element)
            @@list[procedure.name] = procedure
          end
        else
          Rails.logger.info("File #{path} is not a procedure as defined by #{XMLNS}")
        end
      end
      return true
    end

    # Returns the root of the procedures
    def root
      Rails.root.join("config", "procedures")
    end

  end

end

Procedo.load
Rails.logger.info "Loaded procedures: " + Procedo.names.to_sentence
