# require 'procedo/engine/intervention/parameter'

module Procedo
  module Engine
    class Intervention
      class ProductParameter < Procedo::Engine::Intervention::Parameter
        attr_reader :product, :working_zone, :readings, :read_at

        delegate :get, to: :product

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          if @attributes[:product_id].present?
            @product = Product.find_by(id: @attributes[:product_id])
          end
          if attributes[:working_zone].present?
            @working_zone = Charta.from_geojson(attributes[:working_zone])
          end
          @read_at = intervention.working_periods['0'].started_at if intervention && intervention.working_periods.present?
          @readings = {}.with_indifferent_access
          if @attributes[:readings_attributes]
            @attributes[:readings_attributes].each do |id, attributes|
              add_reading(id, attributes)
            end
          end
        end

        def product_id
          @product ? @product.id : nil
        end

        def product=(record)
          self.product_id = record.id
        end

        def product_id=(id)
          @product = Product.find_by!(id: id)
          impact_dependencies!(:product)
        end

        def working_zone=(value)
          @working_zone = Charta.new_geometry(value)
          impact_dependencies!(:working_zone)
        end

        def add_reading(id, attributes = {})
          reading = Procedo::Engine::Intervention::Reading.new(self, id, attributes)
          @readings[reading.id] = reading
        end

        def reading(indicator_name)
          @readings.each do |_id, reading|
            return reading if reading.name.to_s == indicator_name.to_s
          end
          nil
        end

        def to_hash
          hash = super
          hash[:product_id] = product_id
          hash[:working_zone] = @working_zone ? @working_zone.to_json : nil
          @readings.each do |id, reading|
            next unless reference.reading(reading.name)
            hash[:readings_attributes] ||= {}
            hash[:readings_attributes][id] = reading.to_hash
          end
          hash
        end

        def impact_with(steps)
          raise 'Invalid steps: ' + steps.inspect if steps.size != 1
          impact(steps.first)
        end

        def impact_dependencies!(field)
          super(field)
          impact_on_attributes(field)
          impact_on_readings(field)
          impact_on_parameters(field)
          impact_on_components(field)
        end

        # Impact changes on attributes of parameter based on given field
        def impact_on_attributes(field)
          reference.attributes.each do |attribute|
            next unless field != attribute.name
            next unless attribute.default_value?
            next unless attribute.default_value_with_environment_variable?(field, :self)
            next if attribute.condition? && !usable_attribute?(attribute)
            # value = send(attribute.name)
            # next unless value.blank?
            value = compute_attribute(attribute)
            next if value.blank? || value == send(attribute.name)
            # puts "Update #{attribute.name}"
            value = Charta.new_geometry(value) if value && attribute.name == :working_zone
            send(attribute.name.to_s + '=', value)
          end
        end

        # Impact changes on readings of parameter based on given field
        def impact_on_readings(field)
          reference.readings.each do |ref_reading|
            ir = reading(ref_reading.name)
            next unless ir && ref_reading.default_value?
            next unless ref_reading.default_value_with_environment_variable?(field, :self)
            next if ref_reading.condition? && !usable_reading?(ref_reading)
            # next unless ir.value.blank?
            value = compute_reading(ref_reading)
            if value != ir.value
              # puts "Update reading #{ref_reading.name}"
              ir.value = value
            end
            ir.impact_dependencies!
          end
        end

        def impact_on_parameters(_field)
          procedure.parameters.each do |parameter|
            next unless parameter.is_a?(Procedo::Procedure::ProductParameter)
            intervention_parameters = intervention.parameters_of_name(parameter.name)
            intervention_parameters.each do |ip|
              # Impact handlers
              if parameter.quantified? && ip.quantity_handler
                handler = parameter.handler(ip.quantity_handler)
                if handler && handler.depend_on?(reference_name)
                  # puts "Impact #{parameter.name} #{handler.name} quantity_value"
                  ip.quantity_value = ip.quantity_value
                end
              end
              # Impact attributes
              parameter.attributes.each do |attribute|
                next unless attribute.depend_on?(reference_name)
                next unless ip.usable_attribute?(attribute)
                value = ip.compute_attribute(attribute)
                if value != ip.send(attribute.name)
                  # puts "Impact #{parameter.name} #{attribute.name} attribute"
                  ip.impact(attribute.name)
                end
              end
              # Impact readings
              parameter.readings.each do |reading|
                next unless reading.depend_on?(reference_name)
                next unless ip.usable_reading?(reading)
                value = ip.compute_reading(reading)
                ir = ip.reading(reading.name)
                # puts value.inspect.green
                # puts ir.value.inspect.blue
                if value != ir.value
                  # puts "Impact #{parameter.name} #{reading.name} reading: #{ir.value.inspect}"
                  ir.value = value
                end
              end
            end
          end
        end

        def impact_on_components(_field)
          dependents = procedure.parameters.select { |p| p.depend_on?(self) }
          dependents.each do |component_parameter|
            inputs = intervention.parameters_of_name(component_parameter.name)
            inputs.each do |component_inputs|
              component_inputs.schematic_source = self
            end
          end
        end

        def compute_attribute(attribute)
          intervention.interpret(attribute.default_value_tree, env)
        end

        def compute_reading(reading)
          intervention.interpret(reading.default_value_tree, env)
        end

        # Test if a handler is usable
        def usable_handler?(handler)
          return true unless handler.condition?
          intervention.interpret(handler.condition_tree, env)
        end

        # Test if a attribute is usable
        def usable_attribute?(attribute)
          return true unless attribute.condition?
          intervention.interpret(attribute.condition_tree, env)
        end

        # Test if a reading is usable
        def usable_reading?(reading)
          return true unless reading.condition?
          intervention.interpret(reading.condition_tree, env)
        end

        def env
          { self: self, product: product, working_zone: working_zone, read_at: read_at }
        end
      end
    end
  end
end
