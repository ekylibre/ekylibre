module Procedo
  class MissingAttribute < StandardError
  end

  class MissingProcedure < StandardError
  end

  class NotUniqueIdentifier < StandardError
  end

  XMLNS = "http://www.ekylibre.org/XML/2013/procedures".freeze
  NS_SEPARATOR = "-"

  autoload :Procedure, 'procedo/procedure'
  autoload :Variable,  'procedo/variable'
  autoload :Operation, 'procedo/operation'
  autoload :Task,      'procedo/task'

  @@list = HashWithIndifferentAccess.new

  class << self

    # Returns the names of the procedures
    def procedures
      @@list.keys
    end
    alias :names :procedures

    # Give access to named procedures
    def [](name)
      @@list[name]
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

  # Load all procedures
  load

  Rails.logger.info "Loaded procedures: " + names.to_sentence
end


