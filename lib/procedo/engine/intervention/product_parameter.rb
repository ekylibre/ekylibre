# require 'procedo/engine/intervention/parameter'

module Procedo
  module Engine
    class Intervention
      class ProductParameter < Procedo::Engine::Intervention::Parameter
        attr_reader :product, :working_zone, :readings, :read_at, :assembly, :component

        delegate :get, to: :product

        def initialize(intervention, id, attributes = {})
          super(intervention, id, attributes)
          if @attributes[:product_id].present?
            @product = Product.find_by(id: @attributes[:product_id])
          end
          if attributes[:working_zone].present?
            @working_zone = Charta.new_geometry(attributes[:working_zone])
            @working_zone = @working_zone.convert_to(:multi_polygon)
          end
          if intervention && intervention.working_periods.present?
            first_period_key = intervention.working_periods.keys.sort_by(&:to_i).first
            @read_at = intervention.working_periods[first_period_key].started_at
          end
          @readings = {}.with_indifferent_access
          if @attributes[:readings_attributes]
            @attributes[:readings_attributes].each do |id, attributes|
              add_reading(id, attributes)
            end
          end
          if attributes[:assembly_id].present?
            @assembly = Product.find_by(id: attributes[:assembly_id])
          end
          if attributes[:component_id].present?
            @component = ProductNatureVariantComponent.find_by(id: attributes[:component_id])
          end
        end

        def read_at?
          @read_at.present?
        end

        def product_id
          @product ? @product.id : nil
        end

        def product=(record)
          self.product_id = record.id
        end

        def product?
          @product.present?
        end

        def product_id=(id)
          @product = id.blank? ? nil : Product.find_by!(id: id)
          # Can impact on own attributes, own readings, and other parameters
          impact_dependencies!(:product)
        end

        def working_zone?
          @working_zone.present?
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

        def assembly_id
          @assembly ? @assembly.id : nil
        end

        def assembly_id=(id)
          @assembly = id.blank? ? nil : Product.find_by!(id: id)
          impact_dependencies! :assembly
        end

        def assembly=(record)
          self.assembly_id = Maybe(record).id.or_else(nil)
        end

        def assembly?
          @assembly.present?
        end

        def component_id
          @component ? @component.id : nil
        end

        def component_id=(id)
          @component_id = id.blank? ? nil : ProductNatureVariant.find_by!(id: id)
          impact_dependencies! :component
        end

        def component=(record)
          self.component_id = Maybe(record).id.or_else(nil)
        end

        def component?
          @component.present?
        end

        def to_hash
          hash = super
          hash[:product_id] = product_id if product?
          hash[:working_zone] = @working_zone.to_json if working_zone?
          @readings.each do |id, reading|
            next unless reference.reading(reading.name)
            hash[:readings_attributes] ||= {}
            hash[:readings_attributes][id] = reading.to_hash
          end
          reference.attributes.each do |attribute|
            next unless attribute.compute_filter?
            hash[:attributes] ||= {}
            hash[:attributes][attribute.name] ||= {}
            hash[:attributes][attribute.name][:dynascope] = attribute.scope_hash
          end
          hash[:assembly_id] = assembly_id if assembly?
          hash[:component_id] = component_id if component?
          hash[:errors] = {}
          if reference.display_status.to_s.to_sym == :miscibility
            hash[:errors][:miscibility] = true unless product? && product.france_maaid
          end
          hash
        end

        def to_attributes
          hash = super
          hash[:product_id] = product_id if product?
          hash[:working_zone] = @working_zone.to_json if working_zone?
          @readings.each do |id, reading|
            next unless reference.reading(reading.name)
            hash[:readings_attributes] ||= {}
            hash[:readings_attributes][id] = reading.to_hash
          end
          reference.attributes.each do |attribute|
            next unless attribute.compute_filter?
            hash[:attributes] ||= {}
            hash[:attributes][attribute.name] ||= {}
            hash[:attributes][attribute.name][:dynascope] = attribute.scope_hash
          end
          hash[:assembly_id] = assembly_id if assembly?
          hash[:component_id] = component_id if component?
          hash
        end

        def impact_with(steps)
          if steps.size != 1
            raise ArgumentError, 'Invalid steps: got ' + steps.inspect
          end
          reassign!(steps.first)
        end

        def impact_dependencies!(field = nil)
          super(field)
          impact_on_attributes(field)
          impact_on_readings(field)
          impact_on_components(field)
          impact_on_parameters(field)
          reassign(:assembly)
          reassign(:component)
        end

        # Impact changes on attributes of parameter based on given field
        def impact_on_attributes(field = nil)
          reference.attributes.each do |attribute|
            next unless field != attribute.name
            if attribute.default_value? && attribute.default_value_with_environment_variable?(field, :self)

              next if attribute.condition? && !usable_attribute?(attribute)
              value = compute_attribute(attribute)
              next if value.blank? || value == send(attribute.name)
              value = Charta.new_geometry(value) if value && attribute.name == :working_zone

              assign(attribute.name, value)
            end

            if attribute.compute_filter? && attribute.compute_filter_with_environment_variable?(field, :self)
              attribute.computed_filter = intervention.interpret(attribute.compute_filter_tree, env)
            end
          end
        end

        # Impact changes on readings of parameter based on given field
        def impact_on_readings(field = nil)
          reference.readings.each do |ref_reading|
            ir = reading(ref_reading.name)
            next unless ir && ref_reading.default_value?
            next unless ref_reading.default_value_with_environment_variable?(field, :self)
            next if ref_reading.condition? && !usable_reading?(ref_reading)
            ir.assign(:value, compute_reading(ref_reading))
          end
        end

        def impact_on_components(_field = nil)
          return if reference.components.exclude?(self.name)
          self.assign(:assembly, intervention.interpret(parameter.reference.component_of_tree, env))
        end

        def impact_on_parameters(_field)
          procedure.product_parameters(true).each do |parameter|
            (intervention.parameters_of_name(parameter.name) - [self]).each do |ip|
              # Impact handlers
              if parameter.quantified? && ip.quantity_handler
                handler = parameter.handler(ip.quantity_handler)
                if handler && handler.depend_on?(reference_name)
                  ip.reassign(:quantity_value)
                end
              end
              # Impact attributes
              parameter.attributes.each do |attribute|
                next unless attribute.depend_on?(reference_name) &&
                            ip.usable_attribute?(attribute)
                ip.assign(attribute.name, ip.compute_attribute(attribute))
              end
              # Impact readings
              parameter.readings.each do |reading|
                next unless reading.depend_on?(reference_name) &&
                            ip.usable_reading?(reading)
                ip.reading(reading.name).assign(:value, ip.compute_reading(reading))
              end
              # Impact components
              ip.impact_on_components(_field)
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
          return false if handler.condition_variables.any? { |dependency| intervention.interpret(dependency, env).nil? }
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
          super.merge(product: product, working_zone: working_zone, read_at: read_at)
        end
      end
    end
  end
end
