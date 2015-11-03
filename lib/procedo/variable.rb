module Procedo
  class Variable
    attr_reader :abilities, :birth_nature, :derivative_of, :default_name, :destinations, :default_actor, :default_variant, :handlers, :name, :position, :procedure, :producer_name, :roles, :type, :value, :variety, :new_value

    def initialize(procedure, element, position)
      @procedure = procedure
      @position = position
      @name = element.attr('name').to_sym
      if element.has_attribute?('new')
        @new_variable = true
        @new_value = element.attr('new').to_s
        unless @new_value.match(/\A(parted\-from|produced-by)\:/)
          fail StandardError, "The new variable #{@name} in procedure #{@procedure.name} must specify where does it comes from"
        end
        new_array = @new_value.split(/\s*\:\s*/)
        @birth_nature  = new_array.shift.underscore.to_sym
        @producer_name = new_array.shift.to_sym
      end
      @type = element.has_attribute?('type') ? element.attr('type').underscore.to_sym : :product
      unless [:product, :variant].include?(@type)
        fail StandardError, "Unknown variable type: #{@type.inspect}"
      end
      @default_name = element.attr('default-name').to_s
      @default_actor   = element.has_attribute?('default-actor') ? element.attr('default-actor').underscore.to_sym : :none
      @default_variant = element.has_attribute?('default-variant') ? element.attr('default-variant').underscore.to_sym : :none
      # Handlers
      @handlers = []
      @needs = []
      element.xpath('xmlns:handler').each do |el|
        handler = Handler.new(self, el)
        @handlers << handler
        @needs += handler.destinations
        @needs.uniq!
      end
      hnames = @handlers.map(&:name)
      if hnames.size != hnames.uniq.size
        fail StandardError, "Duplicated handlers in #{@procedure.name}##{@name}"
      end
      if @handlers.empty?
        @needs = element.attr('need').to_s.split(/\s*\,\s*/).map(&:to_sym)
        for need in @needs
          @handlers << Handler.new(self, indicator: need)
        end
      end
      @destinations = @handlers.map(&:destinations).flatten.uniq
      @default_destinations = {}.with_indifferent_access
      for destination in @destinations
        attr_name = "default-#{destination}"
        if element.has_attribute?(attr_name)
          @default_destinations[destination] = element.attr(attr_name)
        end
      end
      @value = element.attr('value').to_s
      @abilities = WorkingSet::AbilityArray.load(element.attr('abilities').to_s)
      @abilities.check!
      if element.has_attribute?('variety')
        @variety = element.attr('variety').to_s.strip
      elsif parted?
        @variety = ":#{@producer_name}"
      end
      if element.has_attribute?('derivative-of')
        @derivative_of = element.attr('derivative-of').to_s.strip
      elsif element.has_attribute?('derivative_of')
        @derivative_of = element.attr('derivative_of').to_s.strip
      elsif parted?
        @derivative_of = ":#{@producer_name}"
      end
      @roles = element.attr('roles').to_s.strip.split(/\s*\,\s*/)
      if element.has_attribute?('variant')
        if parted?
          fail StandardError, "'variant' attribute must be removed to limit ambiguity when new variable is parted from another"
        end
        @variant = element.attr('variant').to_s.strip
        if @variant =~ /\A\:/
          unless @procedure.variable_names.include?(@variant[1..-1].to_sym)
            fail StandardError, "Unknown variable for variant attribute: #{@variant}"
          end
        else
          unless Nomen::ProductNatureVariant[@variant]
            fail StandardError, "Unknown variant in product_nature_variants nomenclature: #{@variant}"
          end
        end
      end
    end

    # Returns the name of procedure (LOD)
    def procedure_name
      @procedure.name
    end

    # Translate the name of the variable
    def human_name(options = {})
      "procedure_variables.#{name}".t(options.merge(default: ["labels.#{name}".to_sym, "attributes.#{name}".to_sym, name.to_s.humanize]))
    end

    def inspect
      "<Variable::#{procedure_name}::#{name}>"
    end

    def others
      @procedure.variables.values.select do |v|
        v != self
      end
    end

    #
    def handled?
      @handlers.any?
    end

    # Returns an handler by its name
    def [](name)
      @handlers.find { |h| h.name.to_s == name.to_s }
    end

    #
    def given?
      !@value.blank?
    end

    attr_reader :needs

    def need_population?
      new? && @needs.include?(:population)
    end

    def need_shape?
      new? && @needs.include?(:shape)
    end

    def worked?
      new? || @needs.any?
    end

    def new?
      @new_variable
    end

    def parted?
      new? && @birth_nature == :parted_from
    end

    def produced?
      new? && @birth_nature == :produced_by
    end

    def default_name?
      !@default_name.blank?
    end

    def type_product?
      @type == :product
    end

    def type_variant?
      @type == :variant
    end

    def producer
      @producer ||= @procedure.variables[@producer_name]
    end

    def computed_variety
      if @variety
        if @variety =~ /\:/
          attr, other = @variety.split(/\:/)[0..1].map(&:strip)
          attr = 'variety' if attr.blank?
          attr.gsub!(/\-/, '_')
          unless variable = @procedure.variables[other]
            fail Procedo::Errors::MissingVariable, "Variable #{other.inspect} can not be found"
          end
          return variable.send("computed_#{attr}")
        else
          return @variety
        end
      end
      nil
    end

    def computed_derivative_of
      if @derivative_of
        if @derivative_of =~ /\:/
          attr, other = @derivative_of.split(/\:/)[0..1].map(&:strip)
          attr = 'derivative_of' if attr.blank?
          attr.gsub!(/\-/, '_')
          unless variable = @procedure.variables[other]
            fail Procedo::Errors::MissingVariable, "Variable #{other.inspect} can not be found"
          end
          return variable.send("computed_#{attr}")
        else
          return @derivative_of
        end
      end
      nil
    end

    # Returns scope hash for unroll
    def scope_hash
      hash = {}
      hash[:can_each] = @abilities.join(',') unless @abilities.empty?
      hash[:of_variety] = computed_variety if computed_variety
      hash[:derivative_of] = computed_derivative_of if computed_derivative_of
      hash
    end

    def known_variant?
      !@variant.nil? || parted?
    end

    # Return a ProductNatureVariant based on given informations
    def variant(intervention)
      if @variant =~ /\A\:/
        other = @variant[1..-1]
        return intervention.casts.find_by(variable: other).variant
      elsif Nomen::ProductNatureVariant[@variant]
        unless variant = ProductNatureVariant.find_by(nomen: @variant.to_s)
          variant = ProductNatureVariant.import_from_nomenclature(@variant)
        end
        return variant
      end
      nil
    end

    def variant_variable
      if parted?
        return producer
      elsif @variant =~ /\A\:/
        other = @variant[1..-1]
        return @procedure.variables[other]
      end
      nil
    end

    def variant_indication
      if v = variant_variable
        return 'same_variant_as_x'.tl(x: v.human_name)
      end
      'unknown_variant'.tl
    end

    # Returns default given destination if exists
    def default(destination)
      @default_destinations[destination]
    end

    # Returns backward converters from a given destination
    def backward_converters_from(destination)
      handlers.collect do |handler|
        handler.converters.select do |converter|
          converter.destination == destination && converter.backward?
        end
      end.flatten.compact
    end

    # Returns dependent variables. Variables that point on me
    def dependent_variables
      procedure.variables.values.select do |v|
        # v.producer == self or
        v.variety =~ /\:\s*#{name}\z/ || v.derivative_of =~ /\:\s*#{name}\z/
      end
    end

    # Returns dependings variables. Variables that I point
    def depending_variables
      # self.producer
      [procedure.variables[variety.split(/\:\s*/)], procedure.variables[derivative_of.split(/\:\s*/)]].compact
    end

    # Checks if a given actor might fulfill the procedure's variable. Returns
    # true if all information provided by the variable (variety, derivative_of
    # and/or abilities) match with actor's ones, false if at least one does not
    # fit or is missing
    # @params [Product] actor a Product object or any object responding to
    #   #variety, #derivative_of and #abilities
    # @return [Boolean]
    def fulfilled_by?(actor)
      # do not test created variables
      return false if new?
      expr = []
      expr << "is #{computed_variety}" if @variety.present?
      if @derivative_of.present? && actor.derivative_of.present?
        expr << "derives from #{computed_derivative_of}"
      end
      if @abilities.present?
        expr << @abilities.map { |a| "can #{a}" }.join(' and ')
      end
      return false if expr.empty?
      actor.of_expression(expr.join(' and '))
    end

    # Matches actors to variable. Returns an array of actors fulfilling variable
    # @param [Array<Product>] actors, a list of actors to check
    # @return [Array<Product>]
    def possible_matching_for(*actors)
      actors.flatten!
      result = []
      actors.each do |actor|
        result << actor if fulfilled_by?(actor)
      end
      result
    end

    private

    # Compares two Nomen::Variety items. Returns true if actor's item is the
    # same as variable's one or if actor's item is a child of variable's
    # variety, false otherwise.
    # @param [Nomen::Variety] variable_item current variable own variety or
    #   derivative_of
    # @param [Nomen::Variety] actor_item the actor's variety or derivative_of
    #   to compare
    # @return [Boolean]
    def same_items?(variable_item, actor_item)
      # if possible it is better to squeeze nomenclature items comparison since it's quite slow
      return true if actor_item == variable_item

      begin
        return Nomen::Variety[variable_item] >= actor_item
      rescue # manage the case when there is no item in nomenclature for the varieties to compare
        return false
      end
    end
  end
end
