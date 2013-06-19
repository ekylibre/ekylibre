module Procedures
  class MissingAttribute < StandardError
  end

  XMLNS = "http://www.ekylibre.org/XML/2013/procedures".freeze
  NS_SEPARATOR = "-"

  # This class represent a procedure
  class Procedure

    attr_reader :name, :namespace, :version, :variables, :sub_procedures, :operations

    def initialize(element, options = {})
      name = element.attr("name").to_s.split(NS_SEPARATOR)
      if name.size == 2
        @namespace = name.shift.to_sym
      elsif name.size != 1
        raise ArgumentError.new("Bad name of procedure: #{element.attr("name").to_s.inspect}")
      end
      @name = name.shift.to_s.to_sym
      @version = element.attr("version").to_s
      raise MissingAttribute.new("Attribute 'version' must be given for a <procedure>") if @version.blank?
      @variables = element.xpath("xmlns:variables/xmlns:variable").inject({}) do |hash, variable|
        hash[variable.attr("name").to_s] = Variable.new(self, variable)
        hash
      end
      @sub_procedures = element.xpath("xmlns:sub-procedures/xmlns:sub-procedure").collect do |sub_procedure|
        SubProcedure.new(self, sub_procedure)
      end
      @operations = element.xpath("xmlns:operations/xmlns:operation").collect do |operation|
        Operation.new(self, operation)
      end
    end

    # Returns list of name
    def list
      return [@name.to_s] + children.keys
    end

    def full_name
      (namespace ? namespace.to_s + NS_SEPARATOR + name.to_s : name.to_s)
    end

  end

  class Variable
    attr_reader :name, :cally

    def initialize(cally, element)
      @cally = cally
      @name = element.attr("name")
    end
  end

  class Task
    attr_reader :expression, :operation

    def initialize(operation, element)
      @operation = operation
      @expression = element.attr("do")
    end
  end

  class SubProcedure
    attr_reader :name, :procedure, :parameters

    def initialize(procedure, element)
      @procedure = procedure
      @name = element.attr("name").to_s
      @parameters = element.xpath('xmlns:parameter').inject({}) do |hash, parameter|
        hash[parameter.attr("name").to_s] = Variable.new(self, parameter)
        hash
      end
    end

    def foreign_procedure
      Procedures[self.name]
    end
  end

  class Operation
    attr_reader :name, :procedure, :tasks

    def initialize(procedure, element)
      @procedure = procedure
      @name = element.attr("name")
      @tasks = element.xpath('xmlns:task').collect do |task|
        Task.new(self, task)
      end
    end
  end

  @@list = {}

  class << self

    # Returns the names of the procedures
    def names
      @@list.keys
    end

    # Give access to named procedures
    def [](name)
      @@list[name]
    end

    # Load all files
    def load
      for path in Dir.glob(root.join("*.xml"))
        f = File.open(path, "rb")
        document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
        # Add a better syntax check
        if document.root.namespace.href.to_s == XMLNS
          document.root.xpath('xmlns:procedure[@status="frozen"]').each do |procedure|
            name = procedure.attr("name").to_s
            n = Procedure.new(procedure)
            @@list[n.full_name] = n
          end
        else
          Rails.logger.info("File #{path} is not a procedure as defined by #{XMLNS}")
        end
      end
    end

    # Returns the root of the procedures
    def root
      Rails.root.join("config", "nomenclatures")
    end

  end

  # Load all procedures
  load

  Rails.logger.info "Loaded procedures: " + names.to_sentence

end


