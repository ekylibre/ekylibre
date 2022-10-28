# frozen_string_literal: true

# Relation
class InterventionTemplate < ApplicationRecord
  class ProductParameter < ApplicationRecord
    self.table_name = "intervention_template_product_parameters"

    belongs_to :intervention_template, class_name: InterventionTemplate, foreign_key: :intervention_template_id
    belongs_to :product_nature, class_name: ProductNature, foreign_key: :product_nature_id
    belongs_to :product_nature_variant, class_name: ProductNatureVariant, foreign_key: :product_nature_variant_id

    has_many :daily_charges, class_name: DailyCharge, dependent: :destroy, foreign_key: :intervention_template_product_parameter_id
    has_many :budget_items, class_name: ActivityBudgetItem, dependent: :destroy, foreign_key: :product_parameter_id

    # Validation
    validates :quantity, presence: true
    validates :product_nature, presence: true, unless: :product_nature_variant_id?
    validates :product_nature_variant, presence: true, unless: :product_nature_id?
    validates :unit, presence: true, if: :quantitiy_positive?, unless: :procedure_is_plant?

    attr_accessor :product_name

    before_save do
      if product_nature_variant.present?
        self.product_nature_id = self.product_nature_variant.nature.id
      end
    end

    # Need to access product_name in js
    def attributes
      super.merge(product_name: '')
    end

    def quantitiy_positive?
      quantity || 0 > 0
    end

    def measure
      Measure.new(quantity, procedure_unit)
    end

    def unit_symbol
      Onoma::Unit[procedure_unit]&.symbol
    end

    def unit_per_area?
      %i[volume_area_density mass_area_density surface_area_density].include? Onoma::Unit[procedure_unit]&.dimension
    end

    def find_general_product_type
      return :tool if has_product_parameter?(intervention_template.tools)
      return :doer if has_product_parameter?(intervention_template.doers)
      return :input if has_product_parameter?(intervention_template.inputs)
      return :output if has_product_parameter?(intervention_template.outputs)
    end

    def has_product_parameter?(relation)
      relation
        .where(id: id)
        .any?
    end

    def quantity_in_unit(area)
      if procedure_unit == "unity"
        return self.quantity * area
      end

      quantity = self.quantity
        .in(procedure_unit)
        .convert(procedure_unit.gsub(/_per_.*/, '') + '_per_hectare')
        .to_f

      quantity * area
    end

    # return global quantity in unit @Measure
    def global_quantity_in_unit(area_in_hectare)
      global_quantity = nil
      # if tool or doer
      if %i[tool doer].include?(self.find_general_product_type)
        global_quantity =  intervention_template.time_per_hectare * self.quantity * area_in_hectare
        global_quantity.in(:hours).round(2)
      end
      # if input or output
      if %i[input output].include?(self.find_general_product_type)
        if self.unit_per_area?
          short_unit = procedure_unit.split('_per_').first
          puts short_unit.inspect.yellow
          area_unit = procedure_unit.split('_per_').last
          puts area_unit.inspect.yellow
          area_coef = Measure.new(1.0, area_unit.to_sym).convert(:hectare).to_f
          puts area_coef.inspect.yellow
          global_quantity = (self.quantity * (area_in_hectare / area_coef)).in(short_unit.to_sym).round(2)
          puts global_quantity.inspect.green
        elsif procedure_unit == "unity"
          global_quantity = (self.quantity * area_in_hectare).in(:unity).round(2)
        else
          product_parameter.quantity.in(product_parameter.procedure_unit.to_sym)
        end
      end
      global_quantity
    end

    def quantity_with_unit
      if is_input_or_output
        if procedure_unit == "unity"
          "#{quantity} #{:unit.tl}"
        else
          measure.l(precision: 1)
        end
      else
        quantity.l(precision: 1)
      end
    end

    def cost_amount_computation(nature: :intervention)
      started_at = Time.now
      options = { quantity: quantity.to_d }
      if is_doer_or_tool
        # use hour_equipment unit for equipment and hour unit for other (doer, service...)
        clean_unit = is_tool ? Unit.import_from_lexicon(:hour_equipment) : Unit.import_from_lexicon(:hour_worker)
        unit_name = Onoma::Unit.find(:hour).human_name
        unit_name = unit_name.pluralize if quantity > 1
        options[:unit] = clean_unit
        options[:unit_name] = unit_name
        options[:catalog_usage] = :cost
        options[:catalog_item] = product_nature_variant&.default_catalog_item(options[:catalog_usage], started_at, options[:unit], :dimension) || nil
      elsif is_input
        if self.unit_per_area?
          clean_unit = Unit.import_from_lexicon(procedure_unit.split('_per_').first)
        else
          clean_unit = Unit.import_from_lexicon(procedure_unit)
        end
        unit_name = Onoma::Unit.find(clean_unit.onoma_reference_name).human_name
        options[:unit] = clean_unit
        options[:unit_name] = unit_name
        options[:catalog_usage] = :purchase
        options[:catalog_item] = product_nature_variant&.default_catalog_item(options[:catalog_usage], started_at, options[:unit]) || nil
      else
        options[:unit] = Unit.import_from_lexicon(:unity)
        options[:unit_name] = 'unit'
        options[:catalog_usage] = :cost
        options[:catalog_item] = nil
      end
      return InterventionParameter::AmountComputation.quantity(:catalog, options)
    end

    private

      def procedure_is_plant?
        procedure['type'] == 'plant'
      end

      # find unit corresponding to handler
      # handler correspond to input/output name in procedure xml
      # <input name="fertilizer" ... <> procedure[:type] = fertilizer
      # <handler name="ton" indicator="mass_area_density" unit="ton_per_hectare" ..../>
      # or <handler indicator="volume_area_density" unit="liter_per_hectare" .../>
      # or <handler name="population"/> ...
      def procedure_handler
        return nil if is_doer_or_tool

        # find all handlers for an input or an ouptut for parameter in procedure[:type] JSONB columns
        handlers = intervention_template
          .procedure.parameters
          .find { |p| p.name == procedure['type'].to_sym }
          .handlers

        if handlers.find { |h| h.name.to_s == unit.to_s }.present?
          handlers.find { |h| h.name.to_s == unit.to_s }
        elsif handlers.find { |h| h.unit&.name == unit.to_s }.present?
          handlers.find { |h| h.unit&.name == unit.to_s }
        else
          nil
        end

      end

      def procedure_unit
        handler = procedure_handler
        if handler.nil? || unit == "unit" || unit == "unity"
          "unity"
        elsif handler.unit?
          handler.unit.name
        elsif handler.name == "population" || unit == "population"
          product_nature_variant.default_unit_name
        else
          nil
        end
      end

      def is_input_or_output
        %i[input output].include?(find_general_product_type)
      end

      def is_doer_or_tool
        %i[doer tool].include?(find_general_product_type)
      end

      def is_tool
        %i[tool].include?(find_general_product_type)
      end

      def is_input
        %i[input].include?(find_general_product_type)
      end
  end
end
