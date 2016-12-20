# require 'procedo/procedure'

module Procedo
  # The module parse XML procedures.
  # More documentation on schema can be found on http://wiki.ekylibre.org
  # Sample:
  #
  #   <?xml version="1.0"?>
  #   <procedures xmlns="http://www.ekylibre.org/XML/2013/procedures">
  #     <procedure name="sowing" categories="planting" actions="sowing">
  #       <parameters>
  #         <parameter name="seeds" type="input" filter="is seed and derives from plant and can grow"
  #           default-name="{{variant}} - [{{birth_day}}/{{birth_month}}/{{birth_year}}] - [{{derivative_of}}]">
  #           <handler indicator="population"/>
  #           <handler indicator="net_mass" unit="kilogram" if="self.net_mass? & self.net_mass(kilogram) > 0"
  #             to="population" backward="value * self..net_mass(kilogram)" forward="value / self..net_mass(kilogram)"/>
  #           <handler indicator="mass_area_density" unit="kilogram_per_hectare"
  #             if="self.net_mass? & self.net_mass(kilogram) > 0 & cultivation.net_surface_area? & cultivation.net_surface_area(hectare) > 0"
  #             to="population" backward="(value * self..net_mass(kilogram)) / cultivation.net_surface_area(hectare)"
  #             forward="(value * cultivation.net_surface_area(hectare)) / self..net_mass(kilogram)"/>
  #         </parameter>
  #         <tool name="sower" filter="can sow"/>
  #         <doer name="driver" filter="can drive(equipment) and can move"/>
  #         <parameter name="tractor" type="tool" filter="can tow(equipment) and can move"/>
  #         <group name="zone">
  #           <parameter name="land_parcel" type="target" filter="can store(plant)" default-actor="storage"/>
  #           <parameter name="cultivation" type="output" variety="derivative-of: seeds"
  #             filter="is derivative-of: seeds" default-name="{{variant}} [{{birth_month_abbr}}. {{birth_year}}] ({{container}})"
  #             default-shape=":land_parcel" default-variant="production">
  #             <handler indicator="shape">
  #               <converter to="shape" forward="intersection(value, land_parcel.shape)" backward="value"/>
  #               <converter to="population" forward="area(value) / cultivation..net_surface_area(square_meter)"/>
  #             </handler>
  #           </parameter>
  #         </group>
  #       </parameters>
  #     </procedure>
  #   </procedures>
  #
  class XML
    class << self
      # Parse an XML procedures file with one or many procedures
      # Returns a list of Procedo::Procedure
      def parse(file)
        collection = []
        f = File.open(file, 'rb')
        document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
        # Add a better syntax check
        if document.root.namespace.href.to_s == XML_NAMESPACE
          document.root.xpath('xmlns:procedure').each do |element|
            collection << parse_procedure(element)
          end
        else
          Rails.logger.info("File #{path} is not a procedure as defined by #{XML_NAMESPACE}")
        end
        collection
      end

      # Parse a DOM element of and XML procedure corresponding to a <procedure>
      def parse_procedure(element)
        # Create procedure
        name = element.attr('name').to_sym
        options = {}
        options[:required] = true if element.attr('required').to_s == 'true'
        options[:categories] = element.attr('categories')
                                      .to_s
                                      .split(/[\s\,]+/)
                                      .map(&:to_sym)
        options[:mandatory_actions] = element.attr('actions')
                                             .to_s
                                             .split(/[\s\,]+/)
                                             .map(&:to_sym)
        options[:optional_actions] = element.attr('optional-actions')
                                            .to_s.split(/[\s\,]+/)
                                            .map(&:to_sym)
        options[:maintenance] = (element.attr('maintenance').to_s == 'true')
        options[:deprecated] = (element.attr('deprecated').to_s == 'true')

        procedure = Procedo::Procedure.new(name, options)

        # Adds parameters
        parameters_count = element.xpath('xmlns:parameters').count
        if parameters_count > 1
          raise "Too many <parameters> markup in #{procedure.name}. Only one accepted."
        elsif parameters_count < 1
          raise "No <parameters> markup in #{procedure.name}. One is needed."
        end
        parse_group_children(procedure, element.xpath('xmlns:parameters').first)

        # Check procedure validity
        # procedure.check!

        procedure
      end

      # Parse list of children of a <parameter-group> or <parameters> tag
      def parse_group_children(procedure, element, options = {})
        element.children.each do |child|
          if child.name == 'parameter' || Procedo::Procedure::ProductParameter::TYPES.include?(child.name.to_sym)
            parse_parameter(procedure, child, options)
          elsif %w(group parameter-group).include?(child.name)
            parse_parameter_group(procedure, child, options)
          elsif child.element?
            raise "Unexpected child: #{child.name}"
          end
        end
      end

      # Parse <parameter>
      def parse_parameter(procedure, element, options = {})
        locals = {}
        name = element.attr('name').to_sym
        if element.name != 'parameter'
          type = element.name.to_sym
          if element.has_attribute?('type')
            raise "'type' attribute is not supported in a <#{element.name}> element"
          end
        else
          type = element.attr('type').underscore.to_sym
        end
        raise "No type given for #{name} parameter" unless type
        %w(filter cardinality).each do |info|
          if element.has_attribute?(info)
            locals[info.underscore.to_sym] = element.attr(info).to_s
          end
        end
        %w(component-of).each do |attribute|
          if element.has_attribute?(attribute)
            locals[attribute.underscore.to_sym] = element.attr(attribute).to_s
          end
        end
        parent = options[:group] || procedure
        parameter = parent.add_product_parameter(name, type, options.merge(locals))
        # Handlers
        element.xpath('xmlns:handler').each do |el|
          parse_handler(parameter, el)
        end
        # Attributes
        element.xpath('xmlns:attribute').each do |el|
          parse_attribute(parameter, el)
        end
        # Readings
        element.xpath('xmlns:reading').each do |el|
          parse_reading(parameter, el)
        end
      end

      # Parse <handler> of parameter
      def parse_handler(parameter, element)
        # Extract attributes from XML element
        options = %w(forward backward indicator unit to name if datatype).each_with_object({}) do |attr, hash|
          hash[attr.to_sym] = element.attr(attr) if element.has_attribute?(attr)
          hash
        end

        name = options.delete(:name) || options[:indicator]

        handler = parameter.add_handler(name, options)
        # Converters
        if element.xpath('xmlns:converter').any?
          Rails.logger.warn "Converters are no more supported (in #{parameter.procedure_name}/#{parameter.name})"
        end
      end

      # Parse <attribute> of parameter
      def parse_attribute(parameter, element)
        parse_setter(parameter, :attribute, element)
      end

      # Parse <reading> of parameter
      def parse_reading(parameter, element)
        parse_setter(parameter, :reading, element)
      end

      def parse_setter(parameter, type, element)
        name = element.attr('name')
        options = {}
        if element.has_attribute?('value')
          options[:default_value] = element.attr('value')
          options[:hidden] = true
        elsif element.has_attribute?('default-value')
          options[:default_value] = element.attr('default-value')
        end
        options[:if] = element.attr('if') if element.has_attribute?('if')

        options[:compute_filter] = element.attr('compute-filter') if element.has_attribute?('compute-filter')
        options[:filter] = element.attr('filter') if element.has_attribute?('filter')
        setter = parameter.send("add_#{type}", name, options)
        parse_computations(setter, element)
      end

      def parse_computations(item, element)
        element.xpath('xmlns:compute').each do |el|
          parse_computation(item, el)
        end
      end

      def parse_computation(item, element)
        expression = element.attr('expr').strip
        destinations = element.attr('to').strip.split(/\s*\,\s*/)
        options = {}
        options[:if] = element.attr('if') if element.has_attribute?('if')
        item.add_computation(expression, destinations, options)
      end

      # Parse <parameter-group> element
      def parse_parameter_group(procedure, element, options = {})
        unless element.has_attribute?('name')
          raise Procedo::Errors::MissingAttribute, "Missing name for parameter-group in #{procedure.name} at line #{element.line}"
        end
        name = element.attr('name').to_sym
        options = {}
        if element.has_attribute?('cardinality')
          options[:cardinality] = element.attr('cardinality').to_s
        end
        parent = options[:group] || procedure
        group = parent.add_group_parameter(name, options)
        parse_group_children(procedure, element, group: group)
      end
    end
  end
end
