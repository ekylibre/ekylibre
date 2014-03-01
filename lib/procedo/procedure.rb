# -*- coding: utf-8 -*-
module Procedo

  FORMULA_TRUC = {
    shape: ["whole#net_surface_area"]
  }

  class UnavailableReading < StandardError
  end

  class CompiledVariable
    attr_accessor :destinations, :handlers, :procedure, :actor, :variant

    def initialize(procedure)
      raise "Invalid procedure" unless procedure.is_a?(Procedo::CompiledProcedure)
      @procedure = procedure
      @destinations = {}.with_indifferent_access
      @handlers = {}.with_indifferent_access
      @actor = nil
      @variant = nil
    end

    def now
      @procedure.now!
    end

    def actor_id
      (@actor ? @actor.id : nil)
    end

    def variant_id
      (@variant ? @variant.id : nil)
    end

  end

  class Rubyist

    attr_reader :variables, :compiled, :value_calls_count
    attr_accessor :value, :self_value

    def initialize(options = {})
      @self_value  = options[:self]  || "self"
      @value = options[:value] || "value"
    end

    def compile(object)
      @variables = []
      @value_calls_count = 0
      @compiled = rewrite(object)
      return compiled
    end

    protected

    def rewrite(object)
      if object.is_a?(Procedo::HandlerMethod::Expression)
        "(" + rewrite(object.expression) + ")"
      elsif object.is_a?(Procedo::HandlerMethod::Multiplication)
        rewrite(object.head) + " * " + rewrite(object.operand)
      elsif object.is_a?(Procedo::HandlerMethod::Division)
        rewrite(object.head) + " / " + rewrite(object.operand)
      elsif object.is_a?(Procedo::HandlerMethod::Addition)
        rewrite(object.head) + " + " + rewrite(object.operand)
      elsif object.is_a?(Procedo::HandlerMethod::Substraction)
        rewrite(object.head) + " - " + rewrite(object.operand)
      elsif object.is_a?(Procedo::HandlerMethod::Value)
        @value_calls_count += 1
        @value.to_s
      elsif object.is_a?(Procedo::HandlerMethod::Self)
        @self_value.to_s
      elsif object.is_a?(Procedo::HandlerMethod::Variable)
        @variables << object.text_value.to_sym
        "procedure.#{object.text_value}"
      elsif object.is_a?(Procedo::HandlerMethod::Numeric)
        object.text_value.to_s
      elsif object.is_a?(Procedo::HandlerMethod::Reading)
        unit = nil
        if object.options
          unless unit = Nomen::Units[object.options.unit.text_value]
            raise "Valid unit expected in #{object.inspect}"
          end
        end
        rewrite(object.actor) +
          ".get(:" + Nomen::Indicators[object.indicator.text_value].name.to_s +
          (object.is_a?(Procedo::HandlerMethod::IndividualReading) ? ", individual: true" : "") +
          ")" +
          (unit ? ".to_f(:#{unit.name})" : "")
      elsif object.nil?
        "null"
      else
        puts object.class.name.red
        "(" + object.class.name + ")"
      end
    end

  end



  # This class represents a procedure
  class Procedure

    attr_reader :id, :short_name, :namespace, :operations, :natures, :parent, :position, :variables, :variable_names, :version

    def initialize(element, options = {})
      short_name = element.attr("name").to_s.split(NAMESPACE_SEPARATOR)
      if short_name.size == 2
        @namespace = short_name.shift.to_sym
      elsif short_name.size != 1
        raise ArgumentError, "Bad name of procedure: #{element.attr("name").to_s.inspect}"
      end
      @namespace = DEFAULT_NAMESPACE if @namespace.blank?
      @short_name = short_name.shift.to_s.to_sym
      @required = (element.attr('required').to_s == "true" ? true : false)
      @parent = options[:parent] if options[:parent]
      @position = options[:position] || 0

      @system = !!(element.attr('system') == "true")

      # Check version
      @version = element.attr("version").to_s
      unless @version =~ /\A\d+\z/
        raise MissingAttribute, "Valid attribute 'version' must be given for the procedure #{not_so_short_name}"
      end
      @version = @version.to_i

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
      given_roles, position = [], 1
      @variables = element.xpath("xmlns:variables/xmlns:variable").inject(HashWithIndifferentAccess.new) do |hash, variable|
        v = Variable.new(self, variable, position)
        position += 1
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

      # Check producers
      for variable in new_variables
        unless variable.producer.is_a?(Variable)
          raise StandardError, "Unknown variable producer for #{variable.name}"
        end
      end

      # Load operations
      @operations = element.xpath("xmlns:operations/xmlns:operation").inject({}) do |hash, operation|
        hash[operation.attr("id").to_s] = Operation.new(self, operation)
        hash
      end
      unless @operations.keys.size == element.xpath("xmlns:operations/xmlns:operation").size
        raise NotUniqueIdentifier.new("Each operation must have a unique identifier (#{self.name})")
      end

      # Compile it
      self.compile!
    end

    def self.of_nature(nature)
      Procedo.procedures_of_nature(nature)
    end

    # Returns true if the procedure nature match one of the given natures
    def of_nature?(*natures)
      (self.natures & natures).any?
    end

    def not_so_short_name
      namespace.to_s + NAMESPACE_SEPARATOR + short_name.to_s
    end

    def name
      not_so_short_name + VERSION_SEPARATOR + self.version.to_s
    end
    alias :uid :name

    def flat_version
      "v" + self.version.to_s.gsub(/\W/, '_')
    end

    # Returns if the procedure is system
    def system?
      @system
    end

    # Returns if the procedure is required
    def required?
      @required
    end

    # Returns human_name of the procedure
    def human_name
      default = []
      default << "procedures.#{short_name}".to_sym
      default << "labels.procedures.#{not_so_short_name}".to_sym
      default << "labels.procedures.#{short_name}".to_sym
      default << "labels.#{short_name}".to_sym
      default << short_name.to_s.humanize
      return "procedures.#{not_so_short_name}".t(default: default)
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

    def handled_variables
      @variables.values.select(&:handled?)
    end


    def cast_expr(expr, datatype = :string)
      if datatype == :integer
        "#{expr}.to_i"
      elsif datatype == :decimal
        "#{expr}.to_f"
      elsif datatype == :choice
        "#{expr}.to_sym"
      elsif datatype == :measure # No unit expected for now
        "#{expr}.to_f"
      elsif datatype == :boolean
        "['t', 'true', '1'].include?(#{expr}.to_s)"
      elsif datatype == :point or datatype == :geometry
        "(#{expr}.blank? ? Charta::Geometry.empty : Charta::Geometry.new(#{expr}, :WGS84))"
      else
        "#{expr}.to_s"
      end
    end

    # Compile a procedure to manage interventions
    def compile!
      rubyist = Procedo::Rubyist.new
      full_name = ["::Procedo", "CompiledProcedures", self.namespace.to_s.camelcase, self.short_name.to_s.camelcase, "V#{self.version}"]
      code = "class #{full_name.last} < ::Procedo::CompiledProcedure\n\n"
      
      for variable in @variables.values
        code << "  class #{variable.name.to_s.camelcase} < ::Procedo::CompiledVariable\n\n"

        code << "    def initialize(procedure, attributes = {})\n"
        code << "      super(procedure)\n"
        if variable.new?
          code << "      @variant = (attributes[:variant].present? ? ProductNatureVariant.find(attributes[:variant]) : nil)\n"
          for destination in variable.destinations
            code << "      @destinations[:#{destination}] = " + cast_expr("attributes[:destinations][:#{destination}]", Nomen::Indicators[destination].datatype) + "\n"
          end
          for handler in variable.handlers
            code << "      @handlers[:#{handler.name}] = " + cast_expr("attributes[:handlers][:#{handler.name}]", handler.indicator.datatype) + "\n"
          end
        else
          code << "      @actor = (attributes[:actor].blank? ? nil : Product.find(attributes[:actor]))\n"
        end
        code << "    end\n\n"

        # Method to get indicator values on @actor/@variant
        code << "    def get(indicator, options = {})\n"
        if variable.new? and variable.destinations.include?(:shape)
          code << "      if !@destinations[:shape].empty? and indicator == :net_surface_area and !options[:individual]\n"
          code << "        value = @destinations[:shape].area\n"
          code << "      elsif @variant\n"
          code << "        value = @variant.get(indicator)\n"
          code << "      else\n"
          code << "        raise UnavailableReading, \"No way to access \#{'individual ' if options[:individual]}readings for #{variable.name}#\#{indicator.inspect}\"\n"
          code << "      end\n"
        else
          code << "      unless #{variable.new? ? '@variant' : '@actor'}\n"
          code << "        raise UnavailableReading, \"No way to access \#{'individual ' if options[:individual]}readings for #{variable.name}#\#{indicator.inspect}\"\n"
          code << "      end\n"
          if variable.new?
            code << "      value = @variant.get(indicator)\n"
          else
            code << "      value = @actor.get(indicator, at: now, gathering: !options[:individual])\n"
          end
        end
        code << "      unless value\n"
        code << "        raise UnavailableReading, \"Nil \#{'individual' if options[:individual]}reading given #{variable.name}#\#{indicator.inspect}\"\n"
        code << "      end\n"
        code << "      datatype = Nomen::Indicators[indicator].datatype\n"
        code << "      return (datatype == :decimal ? value.to_s('F').to_f : value)\n"
        code << "    end\n\n"

        rubyist.self_value = "self"

        # Destinations
        for destination in variable.destinations
          code << "    def impact_destination_#{destination}!\n"
          code << "      puts \"#{variable.name}#impact_destination_#{destination}!(\#{@destinations[:#{destination}]})\".yellow\n"
          # Updates handlers through backward formula
          for h in variable.handlers.select{|h| h.destination == destination }
            rubyist.value = "@destinations[:#{destination}]"
            rubyist.compile(h.backward_tree)
            code << "      begin\n"
            code << "        value = #{rubyist.compiled}\n"
            code << "        if value != @handlers[:#{h.name}]\n"
            # code << "          puts \"#{variable.name}:handlers:#{h.name}: \#{value.inspect} (\#{@handlers[:#{h.name}].inspect})\".red\n"
            code << "          @handlers[:#{h.name}] = value\n"
            code << "          impact_handler_#{h.name}!\n"
            code << "        end\n"
            code << "      rescue UnavailableReading => e\n"
            code << "        puts e.message.red\n"
            code << "      end\n"
          end
          # Impacts on handlers of other variables that uses "our" destination
          for other in variable.others
            for handler in other.handlers
              if handler.depend_on?(variable.name)
                code << "      # Updates #{handler.name} of #{other.name} if possible\n"
                code << "      procedure.#{other.name}.impact_handler_#{handler.name}!\n"
              end
            end
          end

          code << "    end\n\n"
        end
        
        # Handlers
        for h in variable.handlers
          code << "    def impact_handler_#{h.name}!\n"
          code << "      puts \"#{variable.name}#impact_handler_#{h.name}!\".yellow\n"
          rubyist.value = "@handlers[:#{h.name}]"
          rubyist.compile(h.forward_tree)
          code << "      value = #{rubyist.compiled}\n"
          code << "      if value != @destinations[:#{h.destination}]\n"
          code << "        puts \"#{variable.name}#value: \#{value.inspect} (\#{@destinations[:#{destination}].inspect})\".red\n"
          code << "        @destinations[:#{destination}] = value\n"
          code << "        impact_destination_#{h.destination}!\n"
          code << "      end\n"
          code << "    rescue UnavailableReading => e\n"
          code << "      puts e.message.red\n"
          code << "    end\n\n"
        end

        # Variable
        code << "    def impact_#{variable.new? ? :variant : :actor}!\n"
        code << "      puts \"#{variable.name}#impact_#{variable.new? ? :variant : :actor}!\".yellow\n"


        if variable.others.detect{|other| other.parted? and other.producer == variable }
          variant      = (variable.new? ? "@variant" : "@actor.variant")
          variant_test = (variable.new? ? variant : "@actor and #{variant}")
          code << "      if #{variant_test}\n"
          
          # Set variants of "parted-from variables"
          for other in variable.others
            if other.parted? and other.producer == variable
              code << "        # Updates variant of #{other.name} if possible\n"
              code << "        if procedure.#{other.name}.variant != #{variant}\n"
              code << "          procedure.#{other.name}.variant = #{variant}\n"            
              code << "          procedure.#{other.name}.impact_#{other.new? ? :variant : :actor}!\n"
              code << "        end\n"            
            end
          end
          code << "      end\n"
        end

        # Sets default destinations
        for other in variable.others
          ref = other.name
          for destination in other.destinations
            if other.default(destination) =~ /\A\:\s*#{variable.name}\s*\z/
              code << "      # Updates default #{destination} of #{ref} if possible\n"
              dest = "procedure.#{ref}.destinations[:#{destination}]"
              code << "      if #{dest}.blank? or procedure.updater?(:casting, :#{variable.name})"
              code << " or procedure.updater?(:global, :support)" if variable.default_actor == "storage"
              code << "\n"

              code << "        begin\n"
              code << "          #{dest} = "
              code << "@destinations[:#{destination}] || " if variable.destinations.include?(destination)
              code << "self.get(:#{destination}, at: now)\n"            
              if [:geometry, :point].include?(Nomen::Indicators[destination].datatype)
                code << "          #{dest} = (#{dest}.blank? ? Charta::Geometry.empty : Charta::Geometry.new(#{dest}))\n"
              end
              code << "          procedure.#{ref}.impact_destination_#{destination}!\n"
              code << "        rescue UnavailableReading => e\n"
              code << "          puts e.message.red\n"
              code << "        end\n"            
              code << "      end\n"            
            end
          end
        end

        # Refresh depending handlers
        # for destination in variable.destinations
        #   code << "      impact_destination_#{destination}!\n"
        # end
        for handler in variable.handlers
          if handler.depend_on?(:self)
            code << "      # Updates #{handler.name} of self if possible\n"
            code << "      impact_handler_#{handler.name}!\n"
          end
        end

        for other in variable.others
          for handler in other.handlers
            if handler.depend_on?(variable.name)
              code << "      # Updates #{handler.name} of #{other.name} if possible\n"
              code << "      procedure.#{other.name}.impact_handler_#{handler.name}!\n"
            end
          end
        end
        code << "    end\n\n"
        
        code << "  end\n\n"
      end

      code << "  attr_reader " + @variables.keys.collect{|v| ":#{v}" }.join(', ') + "\n\n"

      code << "  def initialize(casting, global, updater)\n"
      max = @variables.keys.map(&:size).max
      for variable in @variables.keys
        code << "    @#{variable.ljust(max)} = #{variable.camelcase}.new(self, casting[:#{variable}])\n"
      end
      code << "    @__support__ = ProductionSupport.find_by(id: global[:support])\n"
      code << "    @__now__     = global[:at].blank? ? Time.now : global[:at].to_time\n"
      code << "    @__updater__ = updater.split(':').map(&:to_sym)\n"
      code << "  end\n\n"
      
      
      code << "  def impact!\n"
      code << "    if @__updater__.first == :global\n"
      code << "      if @__updater__.second == :support\n"
      for variable in self.variables.values
        if variable.default_actor == "storage" and !variable.new?
          code << "        #{variable.name}.actor = @__support__.storage\n"
          code << "        #{variable.name}.impact_actor!\n"
        end
        if variable.default_variant == "production" and variable.new?
          code << "        #{variable.name}.variant = @__support__.production_variant\n"
          code << "        #{variable.name}.impact_variant!\n"
        end        
      end
      # global:at is called at every interventions form call so we use it
      # TODO replace this with more clean way with a global updater like "global:start"
      code << "      elsif @__updater__.second == :at\n"
      # What to do ? Check existence and destinations of products at this moment ?
      for variable in self.variables.values
        for destination in variable.destinations
          code << "        #{variable.name}.impact_destination_#{destination}!\n"
        end
      end
      code << "      end\n"
      code << "    elsif @__updater__.first == :casting\n"
      code << self.variables.values.collect do |variable|
        vcode  = "if @__updater__.second == :#{variable.name}\n"
        vcode << "  if @__updater__.third == :#{variable.new? ? :variant : :actor}\n"
        vcode << "    #{variable.name}.impact_#{variable.new? ? :variant : :actor}!\n"
        if variable.handlers.any?
          vcode << "  elsif @__updater__.third == :handlers\n"
          vcode << variable.handlers.collect do |handler|
            hcode  = "if @__updater__.fourth == :#{handler.name}\n"
            hcode << "  #{variable.name}.impact_handler_#{handler.name}!\n"
          end.join("els").dig(2)
          vcode << "    else\n"
          vcode << "      raise \"Unknown handler \#{@__updater__.fourth} for #{variable.name}\"\n"
          vcode << "    end\n"
        end
        vcode << "  else\n"
        vcode << "    raise \"Unknown aspect \#{@__updater__.third} for #{variable.name}\"\n"
        vcode << "  end\n"
      end.join("els").dig(3)
      code << "      else\n"
      code << "        raise \"Unknown variable \#{@__updater__.second}\"\n"
      code << "      end\n"
      code << "    else\n"
      code << "      raise \"Unknown part \#{@__updater__.first}\"\n"
      code << "    end\n"
      code << "  end\n\n"

      code << "  def casting\n"
      code << "    { " + @variables.values.collect do |variable|
        vcode = "#{variable.name}: "
        if variable.new?
          vcode << "{variant: @#{variable.name}.variant_id"          
          vcode << ", destinations: {"
          vcode << variable.destinations.collect do |destination|
            indicator = Nomen::Indicators[destination]
            if [:geometry, :point].include?(indicator.datatype)
              "#{destination}: @#{variable.name}.destinations[:#{destination}].to_geojson"
            else
              "#{destination}: @#{variable.name}.destinations[:#{destination}]"
            end
          end.join(', ')
          vcode << "}, handlers: {"
          vcode << variable.handlers.collect do |handler|
            indicator = handler.indicator
            if [:measure, :decimal].include?(indicator.datatype)
              "#{handler.name}: @#{variable.name}.handlers[:#{handler.name}].round(3).to_f"
            elsif [:geometry, :point].include?(indicator.datatype)
              "#{handler.name}: @#{variable.name}.handlers[:#{handler.name}].to_geojson"
            elsif indicator.datatype == :integer
              "#{handler.name}: @#{variable.name}.handlers[:#{handler.name}].to_i"
            else
              "#{handler.name}: @#{variable.name}.handlers[:#{handler.name}]"
            end
          end.join(', ')
          vcode << "}"
          vcode << "}"
        else
          vcode << "{actor: @#{variable.name}.actor_id}"          
        end
        vcode
      end.join(",\n").dig(3).strip + "\n"
      code << "    }\n"
      code << "  end\n\n"

      code << "end\n"

      for mod in full_name[0..-2].reverse
        code = "module #{mod}\n" + code.dig + "end"
      end

      if Rails.env.development?
        file = Rails.root.join("tmp", "code", "compiled_procedures", "#{self.name}.rb")
        FileUtils.mkdir_p(file.dirname)
        File.write(file, code)
      end

      class_eval(code, "(procedure #{self.name})")
      Procedo::CompiledProcedure[self.name] = full_name.join("::").constantize
    end

    # Computes what have to be updated if the a given value in
    # the casting is considered to be updated
    # Returns a hash with the list of updates
    def impact(casting, global, updater)
      proc = Procedo::CompiledProcedure[self.name].new(casting, global, updater)
      before = proc.casting
      proc.impact!
      after = proc.casting
      puts before.inspect.red
      puts after.inspect.green
      return after
    end

  end

end
