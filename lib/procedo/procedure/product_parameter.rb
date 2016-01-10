# require 'procedo/procedure/parameter'
# require 'procedo/procedure/handler'

module Procedo
  class Procedure
    # A parameter is used to defined which are the operators, targets, inputs,
    # outputs and tools in procedure.
    class ProductParameter < Procedo::Procedure::Parameter
      attr_reader :filter, :birth_nature, :derivative_of, :default_name,
                  :destinations, :default_actor, :default_variant,
                  :procedure, :producer_name, :roles, :type, :value,
                  :variety, :new_value

      TYPES = [:target, :tool, :doer, :input, :output]

      def initialize(procedure, name, type, options = {})
        super(procedure, name, options)
        @type = type
        unless ProductParameter::TYPES.include?(@type)
          fail ArgumentError, "Unknown parameter type: #{@type.inspect}"
        end
        if options[:filter]
          @filter = options[:filter]
          # # Check filter syntax
          # WorkingSet.parse(@filter)
        end
        @handlers = {}
      end

      # Adds a new handler
      def add_handler(name, options = {})
        handler = Procedo::Procedure::Handler.new(self, name, options)
        if @handlers.key?(handler.name)
          fail ArgumentError, "Handler name already taken: #{name}"
        end
        @handlers[handler.name] = handler
      end

      def handlers
        @handlers.values
      end

      # Returns reflection name for an intervention object
      def reflection_name
        @type.to_s.pluralize.to_sym
      end

      def others
        @procedure.parameters.select { |v| v != self }
      end

      #
      def handled?
        @handlers.any?
      end

      # Returns an handler by its name
      def find_handler(name)
        @handlers[name.to_sym]
      end
      alias_method :[], :find_handler

      # Find best handler for given quantity
      def best_handler_for(quantity)
        if quantity.is_a?(Measure)
          candidates = handlers.select do |h|
            h.measure? && h.dimension_name == quantity.dimension
          end
          return nil unless candidates.any?
          return candidates.first if candidates.count == 1
          best = candidates.select { |h| h.unit.name.to_s == quantity.unit.to_s }
          return (best ? best : candidates.first)
        elsif quantity.is_a?(Numeric)
          candidates = handlers.select { |h| h.indicator.datatype == :decimal }
          return nil unless candidates.any?
          return candidates.first
        elsif quantity.is_a?(Charta::Geometry)
          candidates = handlers.select { |h| h.indicator.datatype == :multi_polygon }
          return nil unless candidates.any?
          return candidates.first
        else
          return nil
        end
      end

      def default_name?
        !@default_name.blank?
      end

      TYPES.each do |the_type|
        send(:define_method, "#{the_type}?".to_sym) do
          type == the_type
        end
      end

      def producer
        @producer ||= @procedure.parameters[@producer_name]
      end

      def computed_variety
        if @variety
          if @variety =~ /\:/
            attr, other = @variety.split(/\:/)[0..1].map(&:strip)
            attr = 'variety' if attr.blank?
            attr.gsub!(/\-/, '_')
            unless parameter = @procedure.parameters[other]
              fail Procedo::Errors::MissingParameter, "Parameter #{other.inspect} can not be found"
            end
            return parameter.send("computed_#{attr}")
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
            unless parameter = @procedure.parameters[other]
              fail Procedo::Errors::MissingParameter, "Parameter #{other.inspect} can not be found"
            end
            return parameter.send("computed_#{attr}")
          else
            return @derivative_of
          end
        end
        nil
      end

      # Returns scope hash for unroll
      def scope_hash
        hash = {}
        hash[:of_expression] = @filter unless @filter.blank?
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
        if @variant =~ /\A\:/
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
        elsif @variant =~ /\A\:/
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
