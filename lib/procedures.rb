module Procedures
  class MissingAttribute < StandardError
  end

  class MissingProcedure < StandardError
  end

  XMLNS = "http://www.ekylibre.org/XML/2013/procedures".freeze
  NS_SEPARATOR = "-"

  # This class represent a procedure
  class Procedure

    attr_reader :id, :name, :namespace, :operations, :natures, :parent, :position, :variables, :version

    def initialize(element, options = {})
      name = element.attr("name").to_s.split(NS_SEPARATOR)
      if name.size == 2
        @namespace = name.shift.to_sym
      elsif name.size != 1
        raise ArgumentError.new("Bad name of procedure: #{element.attr("name").to_s.inspect}")
      end
      @name = name.shift.to_s.to_sym
      @required = (element.attr('required').to_s == "true" ? true : false)
      @parent = options[:parent] if options[:parent]
      @position = options[:position] || 0
      # @id = element.attr("id").to_s
      # raise MissingAttribute.new("Attribute 'id' must be given for a <procedure>") if @id.blank?
      @version = element.attr("version").to_s
      @natures = element.attr('natures').to_s.strip.split(/[\s\,]+/).compact.map(&:to_sym)
      raise MissingAttribute.new("Attribute 'version' must be given for a <procedure>") if @version.blank?
      @variables = element.xpath("xmlns:variables/xmlns:variable").inject({}) do |hash, variable|
        hash[variable.attr("name").to_s] = Variable.new(self, variable)
        hash
      end
      # @procedures = []
      # element.xpath("xmlns:procedures/xmlns:procedure").each_with_index do |procedure, position|
      #   @procedures << Procedure.new(procedure, :parent => self, :position => position)
      # end
      id = 1
      @operations = element.xpath("xmlns:operations/xmlns:operation").collect do |operation|
        Operation.new(self, id, operation)
        id += 1
      end
    end

    # alias :children :procedures

    # Returns a fully-qualified name for the procedure
    def full_name
      (namespace ? namespace.to_s + NS_SEPARATOR + name.to_s : name.to_s)
    end

    # Returns if the procedure is required
    def required?
      @required
    end

    # Returns if the procedure is root
    def root?
      @parent.nil?
    end

    # # Returns self with children recursively as an array
    # def tree
    #   return procedures.inject([self]) do |array, procedure|
    #     array += procedure.tree
    #     array
    #   end
    # end

    # # Returns the full hash of procedured
    # def hash
    #   return self.root.hash unless root?
    #   return self.tree.inject({}) do |hash, procedure|
    #     hash[procedure.id] = procedure
    #     hash
    #   end
    # end

    # Returns the root procedure
    def root
      @root ||= (self.parent ? self.parent.root : self)
    end

    # Returns the next procedure from a given uid
    def followings_of(uid)
      p = self.hash[uid]
      raise ArgumentError.new("Unknown UID: #{uid.inspect}") unless p
      list = self.root.tree
      if i = list.index(p)
        return [] if (i + 1 == list.size)
        valids = []
        begin
          i += 1
          valids << list[i]
        end while !valids.last.required?
        return valids
      else
        raise StandardError.new("What???")
      end
    end

    # Return next sibling if exists
    def next_sibling
      @next_sibling ||= self.parent.children[self.position + 1]
    end

    # Return previous sibling if exist
    def previous_sibling
      return nil if self.position <= 0
      @next_sibling ||= self.parent.children[self.position - 1]
    end

    # Returns human_name of the procedure
    def human_name
      "procedures.#{name}".t(:default => ["labels.procedures.#{name}".to_sym, "labels.#{name}".to_sym, name.to_s.humanize])
    end

  end

  class Variable
    attr_reader :name, :procedure, :value, :abilities, :variety

    def initialize(procedure, element)
      @procedure = procedure
      @name = element.attr("name").to_sym
      @new = !element.attr("new").blank?
      @value = element.attr("value").to_s
      @abilities = element.attr("abilities").to_s
      @variety = element.attr("variety").to_s
    end

    def human_name
      "variables.#{name}".t(:default => ["labels.#{name}".to_sym, "attributes.#{name}".to_sym, name.to_s.humanize])
    end

    def given?
      !@value.blank?
    end

    def new?
      @new
    end

  end

  class Task
    attr_reader :expression, :operation

    def initialize(operation, element)
      @operation = operation
      @expression = element.attr("do")
    end

  end

  class Operation
    attr_reader :id, :procedure, :tasks

    def initialize(procedure, id, element)
      @procedure = procedure
      @id = id
      @tasks = element.xpath('xmlns:task').collect do |task|
        Task.new(self, task)
      end
    end
  end

  @@list = HashWithIndifferentAccess.new

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
            # procedure = Procedure.new(element)
            # @@list[procedure.name] = procedure
            procedure = Procedure.new(element)
            @@list[procedure.name] = procedure
          end
        else
          Rails.logger.info("File #{path} is not a procedure as defined by #{XMLNS}")
        end
      end
      return true

      # browse_documents do |document|
      #   document.root.xpath('xmlns:procedure[@status="frozen"]').each do |procedure|
      #     name = procedure.attr("name").to_s
      #     p = Procedure.new(procedure)
      #     @@list[p.full_name] = p
      #   end
      # end
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


