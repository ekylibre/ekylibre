module Procedo

  # This class represents a procedure
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
      @operations = element.xpath("xmlns:operations/xmlns:operation").collect do |operation|
        Operation.new(self, operation)
      end
      unless @operations.size == @operations.map(&:id).uniq.size
        raise NotUniqueIdentifier.new("Each operation must have a unique identifier (#{procedure.name}-#{procedure.version})")
      end
    end

    def self.of_nature(nature)
      Procedo.procedures_of_nature(nature)
    end

    # Returns true if the procedure nature match one of the given natures
    def of_nature?(*natures)
      puts "> " + self.natures.inspect
      puts "& " + natures.inspect
      puts "= " + (self.natures & natures).inspect
      (self.natures & natures).any?
    end


    # Returns a fully-qualified name for the procedure
    def full_name
      (namespace ? namespace.to_s + NS_SEPARATOR + name.to_s : name.to_s)
    end

    # Signature
    def signature
      self.full_name + "-" + self.version
    end

    # Returns if the procedure is required
    def required?
      @required
    end

    # Returns human_name of the procedure
    def human_name
      "procedures.#{name}".t(:default => ["labels.procedures.#{name}".to_sym, "labels.#{name}".to_sym, name.to_s.humanize])
    end

    # Returns the fixed time for a procedure
    def minimal_duration
      return self.operations.map(&:duration).compact.sum
    end
    alias :fixed_duration :minimal_duration

    # Returns the spread duration for operation with unknown duration
    def spread_time(duration)
      return (duration - self.fixed_duration).to_d / self.operations.select(&:no_duration?).size
    end


  end

end
