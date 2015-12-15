# require 'procedo/converter'
require 'procedo/parameter_group'
require 'procedo/compilers'
require 'procedo/compiled_procedure'
require 'procedo/compiled_variable'

module Procedo
  FORMULA_TRUC = {
    shape: ['whole#net_surface_area']
  }

  # This class represents a procedure
  class Procedure
    attr_reader :id, :name
    delegate :add_parameter, :add_parameter_group, :each_item, :find, :position_of, to: :root_group

    def initialize(name, options = {})
      @name = name.to_sym
      @categories = options[:categories]
      @mandatory_actions = options[:mandatory_actions] || []
      @optional_actions = options[:optional_actions] || []
      @root_group = Procedo::ParameterGroup.new(self, :root_, cardinality: 1)
      # Compile it
      self.compile!
    end

    # All actions (mandatory and optional)
    def actions
      @mandatory_actions + @optional_actions
    end

    # Retrieve all parameters recursively in group or subgroups
    def parameters
      @root_group.items(true)
    end

    # Lists names of all parameters
    def parameter_names
      @parameter_names ||= parameters.map(&:name)
    end

    def check!
      # Check ungiven roles
      remaining_roles = roles - given_roles.uniq
      if remaining_roles.any?
        fail Procedo::Errors::MissingRole, "Remaining roles of procedure #{name} are not given: #{remaining_roles.join(', ')}"
      end

      # Check producers
      new_parameters.each do |parameter|
        unless parameter.producer.is_a?(Parameter)
          fail Procedo::Errors::UnknownAspect, "Unknown parameter producer for #{parameter.name}"
        end
      end
    end

    def self.of_nature(nature)
      Procedo.procedures_of_nature(nature)
    end

    # Returns true if the procedure nature match one of the given natures
    def of_nature?(*natures)
      (self.natures & natures).any?
    end

    def of_activity_family?(*families)
      (activity_families & families).any?
    end

    def can_compute_duration?
      @duration_tree.present?
    end

    # Returns activity families of the procedure
    def activity_families
      @activity_families ||= natures.map do |n|
        families = Nomen::ProcedureNature[n].activity_families || []
        families.map do |f|
          Nomen::ActivityFamily.all(f)
        end
      end.flatten.uniq.map(&:to_sym)
    end

    def not_so_short_name
      ActiveSupport::Deprecation.warn 'Procedo::Procedure#not_so_short_name is deprecated. Please use Procedo::Procedure#name instead.'
      name
    end

    def short_name
      ActiveSupport::Deprecation.warn 'Procedo::Procedure#short_name is deprecated. Please use Procedo::Procedure#name instead.'
      name
    end
    alias_method :uid, :name

    # Returns if the procedure is required
    def required?
      @required
    end

    # Returns human_name of the procedure
    def human_name(options = {})
      default = []
      default << "labels.procedures.#{name}".to_sym
      default << "labels.#{name}".to_sym
      default << name.to_s.humanize
      "procedures.#{name}".t(options.merge(default: default))
    end

    # Browse each parameter of the procedure in the order
    def each_parameter
      parameters.each do |parameter|
        yield parameter
      end
    end

    # Returns only parameters which must be built during runnning process
    def new_parameters
      parameters.select(&:new?)
    end

    def handled_parameters
      parameters.select(&:handled?)
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
      elsif datatype == :point || datatype == :geometry
        "(#{expr}.blank? ? Charta.empty_geometry : Charta.new_geometry(#{expr}, :WGS84))"
      else
        "#{expr}.to_s"
      end
    end

    # Compile a procedure to manage interventions
    def compile!
      rubyist = Procedo::Compilers::Rubyist.new
      full_name = ['::Procedo', 'CompiledProcedures', name.to_s.camelcase]
      code = "class #{full_name.last} < ::Procedo::CompiledProcedure\n\n"

      # Convenience method to use procedure method like in compiled parameter
      # Should be properly removed one day...
      code << "  def procedure\n"
      code << "    self\n"
      code << "  end\n\n"

      # Adds impact_stopped_at! method to permit to compute duration
      if self.can_compute_duration?
        rubyist.compile(duration_tree)
        code << "  def impact_stopped_at!\n"
        code << "    duration = 3600 * (#{rubyist.compiled})\n"
        code << "    if @__started_at__ && duration\n"
        code << "      @__stopped_at__ = @__started_at__ + duration\n"
        code << "    end\n"
        code << "  end\n\n"
      end

      each_parameter do |parameter|
        code << "  class #{parameter.name.to_s.camelcase} < ::Procedo::CompiledVariable\n\n"

        code << "    def initialize(procedure, attributes = {})\n"
        code << "      super(procedure)\n"
        if parameter.new?
          code << "      @variant = (attributes[:variant].present? ? ProductNatureVariant.find(attributes[:variant]) : nil)\n"
        else
          code << "      @actor = (attributes[:actor].blank? ? nil : Product.find(attributes[:actor]))\n"
        end
        parameter.destinations.each do |destination|
          code << "      @destinations[:#{destination}] = " + cast_expr("attributes[:destinations][:#{destination}]", Nomen::Indicator[destination].datatype) + "\n"
        end
        parameter.handlers.each do |handler|
          code << "      if attributes[:handlers][:#{handler.name}].is_a? Hash\n"
          code << "        @handlers[:#{handler.name}] = " + cast_expr("attributes[:handlers][:#{handler.name}][:value]", handler.indicator.datatype) + "\n"
          code << "      end\n"
        end
        code << "    end\n\n"

        code << "    def present?\n"
        code << "      @#{parameter.new? ? 'variant' : 'actor'}.is_a?(Ekylibre::Record::Base)\n"
        code << "    end\n\n"

        code << "    def has_indicator?(indicator)\n"
        code << "      present? and @#{parameter.new? ? 'variant' : 'actor'}.has_indicator?(indicator)\n"
        code << "    end\n\n"

        # Method to get indicator values on @actor/@variant
        code << "    def get(indicator, options = {})\n"
        if parameter.destinations.include?(:shape)
          code << "      if !@destinations[:shape].empty? and indicator == :net_surface_area and !options[:individual]\n"
          code << "        value = @destinations[:shape].area\n"
          if parameter.new?
            code << "      elsif @variant\n"
            code << "        value = @variant.get(indicator)\n"
          else
            code << "      elsif @actor\n"
            code << "        value = @actor.get(indicator, at: now, gathering: !options[:individual])\n"
          end
          code << "      else\n"
          code << "        raise Procedo::Errors::UnavailableReading, \"No way to access \#{'individual ' if options[:individual]}readings for #{parameter.name}#\#{indicator.inspect}\"\n"
          code << "      end\n"
        else
          code << "      unless #{parameter.new? ? '@variant' : '@actor'}\n"
          code << "        raise Procedo::Errors::UnavailableReading, \"No way to access \#{'individual ' if options[:individual]}readings for #{parameter.name}#\#{indicator.inspect}\"\n"
          code << "      end\n"
          if parameter.new?
            code << "      value = @variant.get(indicator)\n"
          else
            code << "      value = @actor.get(indicator, at: now, gathering: !options[:individual])\n"
          end
        end
        code << "      unless value\n"
        code << "        raise Procedo::Errors::UnavailableReading, \"Nil \#{'individual ' if options[:individual]}reading given #{parameter.name}#\#{indicator.inspect}\"\n"
        code << "      end\n"
        code << "      datatype = Nomen::Indicator[indicator].datatype\n"
        code << "      return (datatype == :decimal ? value.to_s.to_f : value)\n"
        code << "    end\n\n"

        rubyist.self_value = 'self'

        # Destinations
        parameter.destinations.each do |destination|
          code << "    def impact_destination_#{destination}!\n"
          # Updates handlers through backward formula
          parameter.backward_converters_from(destination).each do |converter|
            rubyist.value = "@destinations[:#{destination}]"
            rubyist.compile(converter.backward_tree)
            code << "      begin\n"
            code << "        value = #{rubyist.compiled}\n"
            code << "        if value != @handlers[:#{converter.handler.name}]\n"
            code << "          @handlers[:#{converter.handler.name}] = value\n"
            code << "          impact_handler_#{converter.handler.name}!\n"
            code << "        end\n"
            code << "      rescue Procedo::Errors::UncomputableFormula => e\n"
            code << "        Rails.logger.error e.message\n"
            code << "      end\n"
          end
          # Impacts on handlers of other parameters that uses "our" destination
          parameter.others.each do |other|
            other.handlers.each do |handler|
              if handler.forward_depend_on?(parameter.name)
                code << "      # Updates #{handler.name} of #{other.name} if possible\n"
                code << "      procedure.#{other.name}.impact_handler_#{handler.name}!\n"
              end
            end
          end

          if self.can_compute_duration?
            code << "      # Update stopped_at if possible\n"
            code << "      procedure.impact_stopped_at!\n"
          end

          code << "    end\n\n"
        end

        # Handlers
        parameter.handlers.each do |h|
          rubyist.value = "@handlers[:#{h.name}]"
          # Method to check is handler is usable
          code << "    def can_use_#{h.name}?\n"
          if h.check_usability?
            rubyist.compile(h.usability_tree)
            code << "      #{rubyist.compiled}\n"
          # code << "    rescue\n"
          # code << "      return false\n"
          else
            code << "      return true\n"
          end
          code << "    end\n\n"

          # Method to impact handler's new value
          code << "    def impact_handler_#{h.name}!\n"
          if h.check_usability?
            code << "      return unless can_use_#{h.name}?\n"
          end
          h.forward_converters.each do |converter|
            rubyist.compile(converter.forward_tree)
            code << "      begin\n"
            code << "        value = #{rubyist.compiled}\n"
            code << "        if value != @destinations[:#{converter.destination}]\n"
            code << "          @destinations[:#{converter.destination}] = value\n"
            code << "          impact_destination_#{converter.destination}!\n"
            code << "        end\n"
            code << "      rescue Procedo::Errors::UncomputableFormula => e\n"
            code << "        Rails.logger.error e.message\n"
            code << "      end\n"
          end
          code << "    end\n\n"
        end

        # Actor or Variant
        code << "    def impact_#{parameter.new? ? :variant : :actor}!\n"
        if parameter.others.detect { |other| other.parted? && other.producer == parameter }
          variant      = (parameter.new? ? '@variant' : '@actor.variant')
          variant_test = (parameter.new? ? variant : "@actor and #{variant}")
          code << "      if #{variant_test}\n"

          # Set variants of "parted-from parameters"
          parameter.others.each do |other|
            next unless other.parted? && other.producer == parameter
            code << "        # Updates variant of #{other.name} if possible\n"
            code << "        if procedure.#{other.name}.variant != #{variant}\n"
            code << "          procedure.#{other.name}.variant = #{variant}\n"
            code << "          procedure.#{other.name}.impact_#{other.new? ? :variant : :actor}!\n"
            code << "        end\n"
          end
          code << "      end\n"
        end

        # Sets default destinations
        parameter.others.each do |other|
          ref = other.name
          other.destinations.each do |destination|
            next unless other.default(destination) =~ /\A\:\s*#{parameter.name}\s*\z/
            code << "      # Updates default #{destination} of #{ref} if possible\n"
            dest = "procedure.#{ref}.destinations[:#{destination}]"
            code << "      if #{dest}.blank? or procedure.updater?(:casting, :#{parameter.name})"
            code << ' or procedure.updater?(:global, :support)' if [:storage, :variant_localized_in_storage].include?(parameter.default_actor)
            code << "\n"

            code << "        begin\n"
            code << "          #{dest} = "
            code << "@destinations[:#{destination}] || " if parameter.destinations.include?(destination)
            code << "self.get(:#{destination}, at: now)\n"
            if [:geometry, :point].include?(Nomen::Indicator[destination].datatype)
              code << "          #{dest} = (#{dest}.blank? ? Charta.empty_geometry : Charta.new_geometry(#{dest}))\n"
            end
            code << "          procedure.#{ref}.impact_destination_#{destination}!\n"
            code << "        rescue Procedo::Errors::UncomputableFormula => e\n"
            code << "          Rails.logger.error e.message\n"
            code << "        end\n"
            code << "      end\n"
          end
        end

        unless parameter.new?
          parameter.destinations.each do |destination|
            dest = "@destinations[:#{destination}]"
            code << "        begin\n"
            code << "          #{dest} = self.get(:#{destination}, at: now)\n"
            if [:geometry, :point].include?(Nomen::Indicator[destination].datatype)
              code << "          #{dest} = (#{dest}.blank? ? Charta.empty_geometry : Charta.new_geometry(#{dest}))\n"
            end
            code << "          impact_destination_#{destination}!\n"
            code << "        rescue Procedo::Errors::UncomputableFormula => e\n"
            code << "          Rails.logger.error e.message\n"
            code << "        end\n"
          end
        end

        # Refresh depending handlers
        parameter.handlers.each do |handler|
          if handler.forward_depend_on?(:self)
            code << "      # Updates #{handler.name} of self if possible\n"
            code << "      impact_handler_#{handler.name}!\n"
          elsif handler.backward_depend_on?(:self)
            handler.converters.select { |c| c.backward_depend_on?(:self) }.each do |converter|
              code << "      # Updates #{converter.destination} of self if possible\n"
              code << "      impact_destination_#{converter.destination}!\n"
            end
          end
        end

        parameter.others.each do |other|
          other.handlers.each do |handler|
            if handler.forward_depend_on?(parameter.name)
              code << "      # Updates #{handler.name} of #{other.name} if possible\n"
              code << "      procedure.#{other.name}.impact_handler_#{handler.name}!\n"
            elsif handler.backward_depend_on?(parameter.name)
              handler.converters.select { |c| c.backward_depend_on?(parameter.name) }.each do |converter|
                code << "      # Updates #{converter.destination} of self if possible\n"
                code << "      impact_destination_#{converter.destination}!\n"
              end
            end
          end
        end

        code << "    end\n\n"

        code << "  end\n\n"
      end

      code << '  attr_reader ' + parameter_names.collect { |v| ":#{v}" }.join(', ') + "\n\n"

      code << "  def initialize(casting, global, updater)\n"
      max = parameter_names.map(&:size).max
      parameter_names.each do |parameter|
        code << "    @#{parameter.ljust(max)} = #{parameter.camelcase}.new(self, casting[:#{parameter}])\n"
      end
      code << "    @__support__ = ActivityProduction.find_by(id: global[:support])\n"
      code << "    @__started_at__ = global[:at].blank? ? Time.zone.now : global[:at].to_time\n"
      code << "    @__updater__ = updater.split(':').map(&:to_sym)\n"
      code << "  end\n\n"

      code << "  def impact!\n"
      code << "    if @__updater__.first == :global\n"
      code << "      if @__updater__.second == :support\n"
      each_parameter do |parameter|
        if parameter.new?
          if parameter.default_variant == :production
            code << "        #{parameter.name}.variant = @__support__.production_variant\n"
            code << "        #{parameter.name}.impact_variant!\n"
          end
        else
          if parameter.default_actor == :storage
            code << "        #{parameter.name}.actor = @__support__.storage\n"
            code << "        #{parameter.name}.impact_actor!\n"
          elsif parameter.default_actor == :default_storage_of_support
            code << "        #{parameter.name}.actor = @__support__.storage.default_storage\n"
            code << "        #{parameter.name}.impact_actor!\n"
          elsif parameter.default_actor == :variant_localized_in_storage
            code << "        __localizeds__ = @__support__.storage.localized_variants(@__support__.production_variant, at: now!)\n"
            code << "        if __localizeds__.any?\n"
            code << "          #{parameter.name}.actor = __localizeds__.first\n"
            code << "          #{parameter.name}.impact_actor!\n"
            code << "        end\n"
          elsif parameter.default_actor.to_s =~ /\Afirst_localized_in\:/
            unless v = find(parameter.default_actor.to_s.split(':').second.strip)
              fail Procedo::Errors::UnknownVariable, "Unknown parameter used in #{parameter.default_actor}"
            end
            code << "        if #{v.name}.actor and #{v.name}.actor.containeds(now!).any?\n"
            code << "          #{parameter.name}.actor = #{v.name}.actor.containeds.first\n"
            code << "          #{parameter.name}.impact_actor!\n"
            code << "        end\n"
          elsif parameter.default_actor != :none
            fail Procedo::Errors::InvalidExpression, "Invalid default-actor expression: #{parameter.default_actor.inspect}"
          end
        end
      end
      # global:at is called at every interventions form call so we use it
      # TODO: replace this in a cleaner way with a global updater like "global:start"
      code << "      elsif @__updater__.second == :at\n"
      # What to do ? Check existence and destinations of products at this moment ?
      each_parameter do |parameter|
        parameter.destinations.each do |destination|
          code << "        #{parameter.name}.impact_destination_#{destination}!\n"
        end
      end
      code << "      end\n"
      code << "    elsif @__updater__.first == :casting\n"
      if parameters.any?
        code << parameters.collect do |parameter|
          vcode = "if @__updater__.second == :#{parameter.name}\n"
          vcode << "  if @__updater__.third == :#{parameter.new? ? :variant : :actor}\n"
          vcode << "    #{parameter.name}.impact_#{parameter.new? ? :variant : :actor}!\n"
          if parameter.handlers.any?
            vcode << "  elsif @__updater__.third == :handlers\n"
            vcode << parameter.handlers.collect do |handler|
              hcode  = "if @__updater__.fourth == :#{handler.name}\n"
              hcode << "  #{parameter.name}.impact_handler_#{handler.name}!\n"
            end.join('els').dig(2)
            vcode << "    else\n"
            vcode << "      raise Procedo::Errors::UnknownHandler, \"Unknown handler \#{@__updater__.fourth} for #{parameter.name}\"\n"
            vcode << "    end\n"
          end
          vcode << "  else\n"
          vcode << "    raise Procedo::Errors::UnknownAspect, \"Unknown aspect \#{@__updater__.third} for #{parameter.name}\"\n"
          vcode << "  end\n"
        end.join('els').dig(3)
        code << "      else\n"
        code << "        raise Procedo::Errors::UnknownVariable, \"Unknown parameter \#{@__updater__.second}\"\n"
        code << "      end\n"
      else
        code << "      raise Procedo::Errors::UnknownVariable, \"No parameter at all: \#{@__updater__.second}\"\n"
      end
      code << "    elsif @__updater__.first == :initial\n"
      # Refresh all handlers from all destinations
      each_parameter do |parameter|
        next unless parameter.handlers.any?
        parameter.destinations.each do |destination|
          code << "      #{parameter.name}.impact_destination_#{destination}!\n"
        end
      end
      code << "    else\n"
      code << "      raise Procedo::Errors::UnknownAspect, \"Unknown part \#{@__updater__.first}\"\n"
      code << "    end\n"
      code << "  end\n\n"

      code << "  def casting\n"
      code << "    {\n"
      code << "      started_at: @__started_at__,\n"
      code << "      stopped_at: @__stopped_at__,\n"
      code << "      casting: {\n"
      code << parameters.collect do |parameter|
        vcode = "#{parameter.name}: "
        if parameter.new?
          vcode << "{variant: @#{parameter.name}.variant_id"
        else
          vcode << "{actor: @#{parameter.name}.actor_id"
        end
        if parameter.handlers.any?
          vcode << ', destinations: {'
          vcode << parameter.destinations.collect do |destination|
            indicator = Nomen::Indicator[destination]
            if [:geometry, :point].include?(indicator.datatype)
              "#{destination}: @#{parameter.name}.destinations[:#{destination}].to_geojson"
            else
              "#{destination}: @#{parameter.name}.destinations[:#{destination}]"
            end
          end.join(', ')
          vcode << '}, handlers: {'
          vcode << parameter.handlers.collect do |handler|
            indicator = handler.indicator
            hcode = "#{handler.name}: {value: "
            if [:measure, :decimal].include?(indicator.datatype)
              hcode << "@#{parameter.name}.handlers[:#{handler.name}].round(3).to_f"
            elsif [:geometry, :point].include?(indicator.datatype)
              hcode << "@#{parameter.name}.handlers[:#{handler.name}].to_geojson"
            elsif indicator.datatype == :integer
              hcode << "@#{parameter.name}.handlers[:#{handler.name}].to_i"
            else
              hcode << "@#{parameter.name}.handlers[:#{handler.name}]"
            end
            hcode << ", usable: @#{parameter.name}.can_use_#{handler.name}?"
            hcode << '}'
            hcode
          end.join(', ')
          vcode << '}'
        end
        vcode << '}'
        vcode
      end.join(",\n").strip.dig(4)
      code << "      }\n"
      code << "    }\n"
      code << "  end\n\n"

      code << "end\n"

      full_name[0..-2].reverse_each do |mod|
        code = "module #{mod}\n" + code.dig + 'end'
      end

      if Rails.env.development?
        file = Rails.root.join('tmp', 'code', 'compiled_procedures', "#{name}.rb")
        FileUtils.mkdir_p(file.dirname)
        File.write(file, code)
      end

      class_eval(code, "(procedure #{name})")
      Procedo::CompiledProcedure[name] = full_name.join('::').constantize
    end

    # Computes what have to be updated if the given value in
    # the casting is considered to be updated
    # Returns a hash with the list of updates
    def impact(casting, global, updater)
      proc = Procedo::CompiledProcedure[name].new(casting, global, updater)
      before = proc.casting
      proc.impact!
      after = proc.casting
      after
    end

    # Generates a hash associating one actor (as the hash value) to each
    # procedure parameter (as the hash key) whenever possible
    # @param [Array<Product>] actors a list of actors possibly matching procedure
    #   parameters
    def matching_variables_for(*actors)
      actors.flatten!
      result = {}
      # generating arrays of actors matching each parameter
      # and parameters matching each actor
      actors_for_each_parameter = {}
      each_parameter do |parameter|
        actors_for_each_parameter[parameter] = parameter.possible_matching_for(actors)
      end

      parameters_for_each_actor = actors_for_each_parameter.inject({}) do |res, (parameter, actors_ary)|
        unless actors_ary.blank?
          actors_ary.each do |actor|
            res[actor] ||= []
            res[actor] << parameter
          end
        end
        res
      end

      # cleaning parameters with no actor
      actors_for_each_parameter.each do |parameter, actors_ary|
        if actors_ary.empty?
          result[parameter] = nil
          actors_for_each_parameter.delete(parameter)
        end
      end

      # setting cursors
      current_parameter = current_actor = 0

      while actors_for_each_parameter.values.flatten.compact.present?
        # first, manage all parameters having only one actor matching
        while current_parameter < actors_for_each_parameter.length
          current_parameter_key = actors_for_each_parameter.keys[current_parameter]
          if actors_for_each_parameter[current_parameter_key].count == 1 && actors_for_each_parameter[current_parameter_key].present? # only one actor for the current parameter
            result[current_parameter_key] = actors_for_each_parameter[current_parameter_key].first
            clean(parameters_for_each_actor, actors_for_each_parameter, result[current_parameter_key], current_parameter_key)
            # restart from the beginning
            current_parameter = 0
          else
            current_parameter += 1
          end
        end

        # then, manage first actor having only one parameter matching and go back to the first step
        while current_actor < parameters_for_each_actor.length
          current_actor_key = parameters_for_each_actor.keys[current_actor]
          if parameters_for_each_actor[current_actor_key].count == 1
            current_parameter_key = parameters_for_each_actor[current_actor_key].first
            result[current_parameter_key] = current_actor_key
            clean(parameters_for_each_actor, actors_for_each_parameter, result[current_parameter_key], current_parameter_key)
            # return to first step
            current_actor = 0
            break
          else
            current_actor += 1
          end
        end
        # then, manage the case when no actor has only one parameter matching
        if current_actor >= parameters_for_each_actor.length
          current_parameter = 0
          current_parameter_key = actors_for_each_parameter.keys[current_parameter]
          result[current_parameter_key] = actors_for_each_parameter[current_parameter_key].first unless actors_for_each_parameter[current_parameter_key].nil?
          clean(parameters_for_each_actor, actors_for_each_parameter, result[current_parameter_key], current_parameter_key)
          # return to first step
        end

        # finally, manage the case when there's no more actor to match with parameters
        next unless parameters_for_each_actor.empty?
        actors_for_each_parameter.keys.each do |parameter_key|
          result[parameter_key] = nil
        end

      end
      result.delete_if { |_k, v| v.nil? }
    end

    private

    attr_reader :root_group

    # clean
    # removes newly matched actor and parameter from hashes
    # associating all possible actors for each parameter and
    # all possible parameters for each actor
    # @params:  - actors_hash, parameters_hash, the hashes to clean
    #           - actor, parameter, the values to remove
    def clean(actors_hash, parameters_hash, actor, parameter)
      # deleting actor from hash "actor => parameters"
      actors_hash.delete(actor)
      # deleting actor for all remaining parameters
      parameters_hash.values.each { |ary| ary.delete(actor) }
      # removing current parameter for all remaining actors
      actors_hash.values.each { |ary| ary.delete(parameter) }
      # removing current parameter from hash "parameter => actors"
      parameters_hash.delete(parameter)
    end
  end
end
