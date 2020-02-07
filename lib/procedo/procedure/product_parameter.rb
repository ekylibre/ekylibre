# require 'procedo/procedure/parameter'
# require 'procedo/procedure/handler'

module Procedo
  class Procedure
    # A parameter is used to defined which are the operators, targets, inputs,
    # outputs and tools in procedure.
    class ProductParameter < Procedo::Procedure::Parameter
      include Codeable
      attr_reader :filter, :birth_nature, :default_name, :new_value,
                  :destinations, :default_actor, :default_variant,
                  :display_status, :procedure, :producer_name, :roles,
                  :type, :value

      attr_accessor :variety, :derivative_of

      TYPES = %i[target tool doer input output].freeze

      code_trees :component_of

      def initialize(procedure, name, type, options = {})
        super(procedure, name, options)
        @type = type
        unless ProductParameter::TYPES.include?(@type)
          raise ArgumentError, "Unknown parameter type: #{@type.inspect}"
        end
        if options[:filter]
          @filter = options[:filter]
          # # Check filter syntax
          # WorkingSet.parse(@filter)
        end
        if output?
          self.variety = options[:variety]
          self.derivative_of = options[:derivative_of]
        end
        if input? || target?
          self.component_of = options[:component_of] if options[:component_of]
          @display_status = options[:display_status] if options[:display_status]
        end
        @handlers = {}
        @attributes = {}
        @readings = {}
      end

      def quantified?
        input? || output?
      end

      def beta?
        !@display_status.nil?
      end

      # Adds a new handler
      def add_handler(name, options = {})
        handler = Procedo::Procedure::Handler.new(self, name, options)
        if @handlers.key?(handler.name)
          raise ArgumentError, "Handler name already taken: #{name}"
        end
        @handlers[handler.name] = handler
      end

      # Adds a new attribute
      def add_attribute(name, options = {})
        attribute = Procedo::Procedure::Attribute.new(self, name, options)
        if @attributes.key?(attribute.name)
          raise ArgumentError, "Attribute name already taken: #{name}"
        end
        @attributes[attribute.name] = attribute
      end

      # Adds a new reading
      def add_reading(name, options = {})
        reading = Procedo::Procedure::Reading.new(self, name, options)
        if @readings.key?(reading.name)
          raise ArgumentError, "Reading name already taken: #{name}"
        end
        @readings[reading.name] = reading
      end

      def remove_reading(name)
        @readings.delete(name.to_sym) if @readings.key?(name)
      end

      def handlers
        @handlers.values
      end

      def attributes
        @attributes.values
      end

      def readings
        @readings.values
      end

      def killable_question
        "is_#{name}_completely_destroyed_by_#{procedure.name}".t(
          scope: [:procedure_killable_parameters],
          default: [
            "is_#{name}_completely_destroyed_by_intervention".to_sym,
            "is_this_completely_destroyed_by_#{procedure.name}".to_sym,
            'is_this_completely_destroyed_by_this_intervention'.to_sym
          ]
        )
      end

      # Returns reflection name for an intervention object
      def reflection_name
        @type.to_s.pluralize.to_sym
      end

      def others
        @procedure.parameters.reject { |v| v == self }
      end

      #
      def handled?
        @handlers.any?
      end

      # Returns an handler by its name
      def handler(name)
        @handlers[name.to_sym]
      end

      # Returns an attribute by its name
      def attribute(name)
        raise 'Invalid attribute: ' + name.inspect unless Procedo::Procedure::Attribute::TYPES.include?(name)
        @attributes[name]
      end

      # Returns an reading by its name
      def reading(name)
        @readings[name.to_sym]
      end

      # Find best handler for given quantity
      def best_handler_for(quantity)
        if quantity.is_a?(Measure)
          candidates = handlers.select do |h|
            h.measure? && h.dimension_name == quantity.dimension
          end
          return nil unless candidates.any?
          return candidates.first if candidates.count == 1
          best = candidates.find { |h| h.unit.name.to_s == quantity.unit.to_s }
          (best || candidates.first)
        elsif quantity.is_a?(Numeric)
          candidates = handlers.select { |h| h.indicator.datatype == :decimal }
          return nil unless candidates.any?
          candidates.first
        elsif quantity.is_a?(Charta::Geometry)
          candidates = handlers.select { |h| h.indicator.datatype == :multi_polygon }
          return nil unless candidates.any?
          candidates.first
        end
      end

      def default_name?
        @default_name.present?
      end

      TYPES.each do |the_type|
        send(:define_method, "#{the_type}?".to_sym) do
          type == the_type
        end
      end

      # Return parameters where component-of dependent on current parameter
      def components
        procedure.product_parameters(true).select do |p|
          next unless p.component_of?
          p.component_of? && p.component_of_with_parameter?(name, p == self)
        end
      end

      def producer
        @producer ||= @procedure.parameters[@producer_name]
      end

      def computed_variety
        computed_attr(:variety)
      end

      def computed_derivative_of
        computed_attr(:derivative_of)
      end

      def computed_attr(attribute_name)
        attribute = instance_variable_get(:"@#{attribute_name}")
        return nil unless attribute
        return attribute unless attribute =~ /\:/
        attr, other = attribute.split(/\:/)[0..1].map(&:strip)
        attr = attribute_name.to_s.underscore if attr.blank?
        unless parameter = @procedure.parameters[other]
          raise Procedo::Errors::MissingParameter, "Parameter #{other.inspect} can not be found"
        end
        parameter.send("computed_#{attr}")
      end

      # Returns scope hash for unroll
      def scope_hash
        hash = {}
        hash[:of_expression] = @filter if @filter.present?
        # hash[:can_each] = @abilities.join(',') unless @abilities.empty?
        hash[:of_variety] = computed_variety if computed_variety
        hash[:derivative_of] = computed_derivative_of if computed_derivative_of
        hash
      end

      def known_variant?
        !@variant.nil? || parted?
      end

      # Return a ProductNatureVariant based on given informations
      def variant(intervention)
        if @variant.start_with?(':')
          other = @variant[1..-1]
          return intervention.product_parameters.find_by(parameter: other).variant
        elsif Nomen::ProductNatureVariant[@variant]
          unless variant = ProductNatureVariant.find_by(nomen: @variant.to_s)
            variant = ProductNatureVariant.import_from_nomenclature(@variant)
          end
          return variant
        end
        nil
      end

      def variant_parameter
        if parted?
          return producer
        elsif @variant.start_with?(':')
          other = @variant[1..-1]
          return @procedure.parameters[other]
        end
        nil
      end

      def variant_indication
        if v = variant_parameter
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

      # Returns dependent parameters. Parameters that point on me
      def dependent_variables
        procedure.parameters.select do |v|
          # v.producer == self or
          v.variety =~ /\:\s*#{name}\z/ || v.derivative_of =~ /\:\s*#{name}\z/
        end
      end

      def depend_on?(parameter_name)
        return false if parameter_name == name
        @attributes.values.any? { |a| a.depend_on? parameter_name } ||
          @readings.values.any? { |r| r.depend_on? parameter_name } ||
          @handlers.values.any? { |h| h.depend_on? parameter_name } ||
          (component_of? && component_of_with_parameter?(parameter_name))
      end

      # Returns dependings parameters. Parameters that I point
      def depending_variables
        # self.producer
        [procedure.parameters[variety.split(/\:\s*/)], procedure.parameters[derivative_of.split(/\:\s*/)]].compact
      end

      # Checks if a given actor might fulfill the procedure's parameter. Returns
      # true if all information provided by the parameter (variety, derivative_of
      # and/or abilities) match with actor's ones, false if at least one does not
      # fit or is missing
      # @params [Product] actor a Product object or any object responding to
      #   #variety, #derivative_of and #abilities
      # @return [Boolean]
      def fulfilled_by?(actor)
        # do not test created parameters
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

      # Matches actors to parameter. Returns an array of actors fulfilling parameter
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
      # same as parameter's one or if actor's item is a child of parameter's
      # variety, false otherwise.
      # @param [Nomen::Variety] parameter_item current parameter own variety or
      #   derivative_of
      # @param [Nomen::Variety] actor_item the actor's variety or derivative_of
      #   to compare
      # @return [Boolean]
      def same_items?(parameter_item, actor_item)
        # if possible it is better to squeeze nomenclature items comparison since it's quite slow
        return true if actor_item == parameter_item

        begin
          return Nomen::Variety[parameter_item] >= actor_item
        rescue # manage the case when there is no item in nomenclature for the varieties to compare
          return false
        end
      end
    end
  end
end
