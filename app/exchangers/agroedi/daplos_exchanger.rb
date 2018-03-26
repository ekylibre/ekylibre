module Agroedi
  # Exchanger to import COFTW.isa files from IsaCompta software
  class DaplosExchanger < ActiveExchanger::Base
    def check
      SVF::EdiDaplos2.parse(file)
    rescue SVF::InvalidSyntax
      return false
    end

    def import
      # path = "/home/djoulin/projects/integration-cer-cneidf/tmp/test.dap"
      # file = File.open(path)

      # please refer to lib/svf/norms/edi/daplos_2.yml

      # Load hash to transcode EDI code to procedure
      here = Pathname.new(__FILE__).dirname
      procedures_transcode = {}.with_indifferent_access
      CSV.foreach(here.join('procedures.csv'), headers: true) do |row|
        procedures_transcode[row[0]] = row[1].to_sym
      end

      begin
        daplos = SVF::EdiDaplos2.parse(file)
      rescue SVF::InvalidSyntax
        raise ActiveExchanger::NotWellFormedFileError
      end

      w.count = daplos.interchange.crops.count

      # TODO: check siret

      # crop
      daplos.interchange.crops.each do |crop|
        # get specie and area
        production_nature = MasterProductionNature.where(agroedi_crop_code: crop.crop_specie_edicode).first
        w.info '------------------------------CROP-----------------------------------'
        w.info "crop specie EDI code : #{crop.crop_specie_edicode}"
        if production_nature
          w.info "production_nature : #{production_nature.human_name_fra}".inspect.yellow
        else
          w.info "crop specie EDI code (#{crop.crop_specie_edicode}) doesn't exist in Lexicon ProductionNature".inspect.red
          next
        end

        crop_area = crop.crop_areas.first.area_nature_value_in_hectare.to_f
        max_area = crop_area + (crop_area * 0.05)
        min_area = crop_area - (crop_area * 0.05)

        # find existing activity production with specie and area +/- 5% and then a support
        # TODO add campaign
        activity_production = ActivityProduction.of_cultivation_variety(production_nature.specie).where('size_value <= ?', max_area).where('size_value >= ?', min_area).first
        target = activity_production.support if activity_production
        if target
          w.info "target : #{target.name}".inspect.yellow
        else
          w.info 'no target availables'.inspect.red
          next
        end

        # parse interventions from daplos file and create each one
        crop.interventions.each do |i|
          w.info '------------------------------INTERVENTION-----------------------------------'
          # get intervention nature
          intervention_agroedi_code = RegisteredAgroediCode.where(repository_id: 14, reference_code: i.intervention_nature_edicode).first
          w.info "intervention_agroedi_code : #{intervention_agroedi_code.reference_label}".inspect.green
          # escape sowing and harvesting for the moment
          next if %w[sowing harvesting].any? { |code| procedures_transcode[intervention_agroedi_code.reference_code].to_s.include? code }
          w.info i.intervention_nature_edicode.inspect.green

          procedure = Procedo.find(procedures_transcode[intervention_agroedi_code.reference_code]) if intervention_agroedi_code
          w.info "procedure : #{procedure.name}".inspect.yellow

          # record intervention
          record_default_intervention(i, target, procedure)
        end
        w.check_point
      end
    end

    protected

    # convert measure to variant unit and divide by variant_indicator
    def measure_conversion(population, unit, unit_target_dose)
      value = population
      w.debug value.inspect.yellow
      nomen_unit = nil
      # concat units if needed
      if unit.present? && unit_target_dose.present?
        u = unit.to_s + '_per_' + unit_target_dose.to_s
      elsif unit.present?
        u = unit.to_s
      end
      # case units are symbol
      if u && !Nomen::Unit[u]
        if u = Nomen::Unit.find_by(symbol: u)
          u = u.name.to_s
        else
          raise ActiveExchanger::NotWellFormedFileError, "Unknown unit #{u.inspect}."
        end
      end
      u = u.to_sym if u
      nomen_unit = Nomen::Unit[u] if u
      if value >= 0.0 && nomen_unit
        measure = Measure.new(value, u)
        return measure
      else
        return nil
      end
    end

    # find or create product and variant
    def find_or_create_product(input, at)
      # Load hash to transcode EDI input to nature
      here = Pathname.new(__FILE__).dirname
      inputs_transcode = {}.with_indifferent_access
      CSV.foreach(here.join('inputs.csv'), headers: true) do |row|
        inputs_transcode[row[0]] = row[1].to_sym
      end

      units_transcode = { 'KGM' => :kilogram, 'LTR' => :liter, 'TNE' => :ton, 'NAR' => :unit }

      nature = ProductNature.import_from_nomenclature(inputs_transcode[input.input_nature_edicode])

      variant = nature.variants.where(name: input.input_name, unit_name: units_transcode[input.input_unity_edicode], active: true).first

      w.info "Variant creation - input name : #{input.input_name}".inspect.red

      unless variant

        variant = nature.variants.create!(name: input.input_name, unit_name: units_transcode[input.input_unity_edicode], active: true)

        w.info "Variant creation - Variant : #{variant.name}".inspect.red

        default_indicators = {
          net_mass: Measure.new(1.00, :kilogram),
          net_volume: Measure.new(1.00, :liter)
        }.with_indifferent_access

        default_indicators.each do |indicator_name, value|
          variant.read! indicator_name, value
        end

      end

      if input.input_phytosanitary_number.present?
        variant.france_maaid = input.input_phytosanitary_number
        variant.save!
      end

      if variant.products.any?
        return variant.products.first
      else
        # Check building division presence
        building_division = BuildingDivision.first

        pmodel = variant.nature.matching_model
        # create the product
        matter = pmodel.create!(
          variant: variant,
          initial_born_at: at,
          initial_population: 0.0,
          initial_owner: Entity.of_company,
          initial_container: building_division,
          default_storage: building_division
        )
        w.info "Variant creation with product - Matter : #{matter.name}".inspect.red
        return matter

      end
    end

    def record_default_intervention(i, target, procedure)
      start = i.intervention_started_at
      stop = i.intervention_stopped_at if !i.intervention_stopped_at.blank?
      stop ||= start

      # build base procedure
      attributes = {
        procedure_name: procedure.name,
        actions: procedure.mandatory_actions.map(&:name),
        description: "#{i.intervention_name} | #{i.intervention_guid}"
      }

      ## working_periods
      attributes[:working_periods_attributes] = {
        '0' => {
          started_at: Date.parse(start).strftime('%Y-%m-%d %H:%M'),
          stopped_at: (Date.parse(stop) + 1.hour).strftime('%Y-%m-%d %H:%M')
        }
      }

      ## targets
      procedure.parameters_of_type(:target).each do |support|
        # next unless target.of_expression(support.filter)
        attributes[:targets_attributes] ||= {}
        attributes[:targets_attributes][0] = {
          reference_name: support.name,
          product_id: target.id,
          working_zone: target.shape.to_geojson
        }
      end

      ## inputs
      updaters = []

      i.inputs.each_with_index do |actor, index|
        p = find_or_create_product(actor, Date.parse(start).to_time)

        w.info "product : #{p.name}".inspect.yellow

        unit = Nomen::Unit.find(p.variant.unit_name.to_sym)
        dimension = unit.dimension
        quantity_handler = 'net_' + dimension.to_s

        procedure.parameters_of_type(:input).each do |input|
          w.info "quantity value : #{actor.input_quantity_per_hectare.to_f}".inspect.yellow
          # find measure from quantity
          product_measure = measure_conversion(actor.input_quantity_per_hectare.to_f, unit.name, :hectare)
          w.info "product_measure : #{product_measure}".inspect.yellow
          # find best handler for product measure
          i = input.best_handler_for(product_measure)
          handler = if i.is_a?(Array)
                      input.best_handler_for(product_measure).first.name
                    else
                      input.best_handler_for(product_measure).name
                    end
          w.info "handler : #{handler}".inspect.yellow

          # puts "input : #{input}".inspect.red
          # puts "input filter : #{input.filter}".inspect.green
          next unless p.of_expression(input.filter)

          w.info "quantity value per hectare : #{actor.input_quantity_per_hectare.to_f}".inspect.yellow

          attributes[:inputs_attributes] ||= {}
          attributes[:inputs_attributes][index.to_s] = {
            reference_name: input.name,
            product_id: p.id,
            quantity_handler: handler,
            quantity_value: product_measure.to_f
          }

          # puts "inputs attributes #{attributes}".inspect.yellow

          updaters << "inputs[#{index}]quantity_value"
          break
        end
      end

      ## tools
      attributes[:tools_attributes] ||= {}

      ## doers
      attributes[:doers_attributes] ||= {}

      ## impact
      intervention = Procedo::Engine.new_intervention(attributes)
      updaters.each do |updater|
        intervention.impact_with!(updater)
      end

      ## save

      ::Intervention.create!(intervention.to_attributes)
    end
  end
end
