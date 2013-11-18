module Procedo

  # This class represents a procedure
  class Procedure

    attr_reader :id, :short_name, :namespace, :operations, :natures, :parent, :position, :variables, :variable_names, :version

    def initialize(element, options = {})
      short_name = element.attr("name").to_s.split(NS_SEPARATOR)
      if short_name.size == 2
        @namespace = short_name.shift.to_sym
      elsif short_name.size != 1
        raise ArgumentError.new("Bad name of procedure: #{element.attr("name").to_s.inspect}")
      end
      @short_name = short_name.shift.to_s.to_sym
      @required = (element.attr('required').to_s == "true" ? true : false)
      @parent = options[:parent] if options[:parent]
      @position = options[:position] || 0

      # Check version
      @version = element.attr("version").to_s
      if @version.blank?
        raise MissingAttribute, "Attribute 'version' must be given for a <procedure>"
      end

      # Collect procedure natures
      @natures = element.attr('natures').to_s.strip.split(/[\s\,]+/).compact.map(&:to_sym)

      # Check roles with procedure natures
      roles  = []
      for nature in @natures
        unless item = Nomen::ProcedureNatures[nature]
          raise UnknownProcedureNature, "Procedure nature #{nature} is unknown for #{self.name}."
        end
        # List all roles
        roles += item.roles.collect{|role| "#{nature}-#{role}"}
      end
      roles.uniq!

      # Load variable_names
      @variable_names = []
      for item in element.xpath("xmlns:variables/xmlns:variable")
        @variable_names << item.attr("name").to_sym
      end

      # Load and check variables
      given_roles = []
      @variables = element.xpath("xmlns:variables/xmlns:variable").inject(HashWithIndifferentAccess.new) do |hash, variable|
        v = Variable.new(self, variable)
        for role in v.roles
          if roles.include?(role)
            given_roles << role
          else
            raise UnknownRole, "Role #{role} is ungiveable in procedure #{self.name}"
          end
        end
        hash[variable.attr("name").to_s] = v
        hash
      end

      # Check ungiven roles
      remaining_roles = roles - given_roles.uniq
      if remaining_roles.any?
        raise MissingRole, "Remaining roles of procedure #{self.name} are not given: #{remaining_roles.join(', ')}"
      end

      # Check genitors
      for variable in new_variables
        unless variable.genitor.is_a?(Variable)
          raise StandardError, "Unknown variable genitor for #{variable.name}"
        end
      end

      # Load operations
      @operations = element.xpath("xmlns:operations/xmlns:operation").inject({}) do |hash, operation|
        hash[operation.attr("id").to_i] = Operation.new(self, operation)
        hash
      end
      unless @operations.keys.size == element.xpath("xmlns:operations/xmlns:operation").size
        raise NotUniqueIdentifier.new("Each operation must have a unique identifier (#{self.name})")
      end
    end

    def self.of_nature(nature)
      Procedo.procedures_of_nature(nature)
    end

    # Returns true if the procedure nature match one of the given natures
    def of_nature?(*natures)
      (self.natures & natures).any?
    end

    def not_so_short_name
      namespace.to_s + ":" + short_name.to_s
    end

    def name
      not_so_short_name + "-" + self.version.to_s
    end
    alias :uid :name


    # Returns if the procedure is required
    def required?
      @required
    end

    # Returns human_name of the procedure
    def human_name
      path, default = "procedures.#{short_name}".to_sym, []
      if namespace
        default << path
        default << "labels.procedures.#{not_so_short_name}".to_sym
        path = "procedure.#{not_so_short_name}"
      end
      default << "labels.procedures.#{short_name}".to_sym
      default << "labels.#{short_name}".to_sym
      default << short_name.to_s.humanize
      return path.t(default: default)
    end

    # Returns the fixed time for a procedure
    def minimal_duration
      total_duration = []
      self.operations.each do |id, operation|
        total_duration << operation.duration
      end
      return total_duration.compact.sum
    end
    alias :fixed_duration :minimal_duration

    # Returns the spread duration for operation with unknown duration
    def spread_time(duration)
      is_durations = []
      self.operations.each do |id, operation|
        is_durations << operation.no_duration?
      end
      return (duration - self.fixed_duration).to_d / is_durations.size
    end

    # Returns only variables which must be built during runnning process
    def new_variables
      @variables.values.select(&:new?)
    end

  end

end
