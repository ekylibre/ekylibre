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
      if here.join('procedures.csv')
        CSV.foreach(here.join('procedures.csv'), headers: true) do |row|
          procedures_transcode[row[0]] = row[1].to_sym
        end
      end

      begin
        daplos = SVF::EdiDaplos2.parse(file)
      rescue SVF::InvalidSyntax
        raise ActiveExchanger::NotWellFormedFileError
      end

      w.count = daplos.interchange.crops.count

      # TODO: check siret

      recorded_interventions_with_inputs = {}

      # crop
      imported_interventions = daplos.interchange.crops.map do |crop|
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

        campaign = Campaign.find_by(harvest_year: crop.harvest_year.to_i)

        # find existing activity production with specie and area +/- 5% and then a support and the good campaign
        activity_production = ActivityProduction.of_cultivation_variety(production_nature.specie).of_campaign(campaign).where('size_value <= ?', max_area).where('size_value >= ?', min_area).first

        # update started_on if present
        # if !crop.crop_started_on.blank?
        #  activity_production.started_on = Date.parse(crop.crop_started_on)
        #  activity_production.save!
        # end

        target = activity_production.support if activity_production
        if target
          w.info "target : #{target.name}".inspect.yellow
        else
          w.info 'no target availables'.inspect.red
          next
        end

        # parse interventions from daplos file and create each one
        imported_crop_interventions = crop.interventions.map do |i|
          w.info '------------------------------INTERVENTION-----------------------------------'

          # check dates from production_name
          if activity_production.started_on > i.intervention_started_at.to_date
             activity_production.started_on = i.intervention_started_at.to_date
             activity_production.save!
             w.info "The actvity production started_on has been updated with : #{i.intervention_started_at.to_date}"
          elsif activity_production.stopped_on < i.intervention_started_at.to_date
            activity_production.stopped_on = i.intervention_started_at.to_date
            activity_production.save!
            w.info "The actvity production started_on has been updated with : #{i.intervention_started_at.to_date}"
          elsif i.intervention_stopped_at && activity_production.stopped_on < i.intervention_stopped_at.to_date
            activity_production.stopped_on = i.intervention_stopped_at.to_date
            activity_production.save!
            w.info "The actvity production started_on has been updated with : #{i.intervention_started_at.to_date}"
          end

          # get intervention nature
          intervention_agroedi_code = RegisteredAgroediCode.where(repository_id: 14, reference_code: i.intervention_nature_edicode).first
          w.info "intervention_agroedi_code : #{intervention_agroedi_code.reference_label}".inspect.green
          w.info i.intervention_nature_edicode.inspect.green
          transcoded_procedure = procedures_transcode[intervention_agroedi_code.reference_code]
          procedure = Procedo.find(transcoded_procedure) if intervention_agroedi_code
          w.info "procedure : #{procedure.name}".inspect.yellow
          # next if %w[harvesting].any? { |code| transcoded_procedure.to_s.include? code }
          if %w[sowing_without_plant_output harvesting].any? { |code| transcoded_procedure.to_s.include? code }
            record_complex_intervention(i, target, procedure)
          else
            record_default_intervention(i, target, procedure, recorded_interventions_with_inputs)
          end
        end
        w.check_point
        imported_crop_interventions
      end
      # check and group intervention based on same target, same date and same intervention nature
      imported_interventions = imported_interventions.flatten.uniq.compact
      imported_interventions.group_by do |intervention|
        [intervention.procedure_name, intervention.working_periods.first.started_at, intervention.targets.pluck(:product_id).sort]
      end.values.each do |group|
        group.reduce do |merged_intervention, other_intervention|
          other_intervention.inputs.each { |input| input.tap(&:reload).update(intervention_id: merged_intervention.id) }
          other_intervention.destroy
          merged_intervention.tap(&:reload)
        end
      end
    end

    protected

    def population_conversion(product, population, unit, unit_target_dose = nil, working_area = 0.0.in_square_meter)
      w.info "Method population_conversion - population : #{population.inspect}"
      w.info "Method population_conversion - unit : #{unit.inspect}"
      w.info "Method population_conversion - unit_target_dose : #{unit_target_dose.inspect}"
      if product.is_a?(Product)
        variant = product.variant
      elsif product.is_a?(ProductNatureVariant)
        variant = product
      end
      value = population.to_f
      nomen_unit = nil
      # convert symbol into unit if needed
      if unit.present? && !Nomen::Unit[unit]
        if u = Nomen::Unit.find_by(symbol: unit)
          unit = u.name.to_s
        else
          raise ActiveExchanger::NotWellFormedFileError, "Unknown unit #{unit.inspect} for variant #{variant.name.inspect}."
        end
      end
      unit = unit.to_sym if unit
      nomen_unit = Nomen::Unit[unit] if unit
      #
      w.debug value.inspect.yellow
      if value >= 0.0 && nomen_unit
        measure = Measure.new(value, unit)
        w.info "Method population_conversion - measure : #{measure.inspect.yellow}"
        w.info "Method population_conversion - variant : #{variant.name.inspect.yellow}"
        if measure.dimension == :volume
          variant_indicator = variant.send(:net_volume)
          if variant_indicator.value.to_f != 0.0
            population_value = (measure.to_f(variant_indicator.unit.to_sym) / variant_indicator.value.to_f).in(variant_indicator.unit.to_sym)
          else
            raise "No way to divide by zero : variant indicator value is #{variant_indicator.inspect}"
          end
        elsif measure.dimension == :mass
          variant_indicator = variant.send(:net_mass)
          if variant_indicator.value.to_f != 0.0
            population_value = (measure.to_f(variant_indicator.unit.to_sym) / variant_indicator.value.to_f).in(variant_indicator.unit.to_sym)
          else
            raise "No way to divide by zero : variant indicator value is #{variant_indicator.inspect}"
          end
        elsif measure.dimension == :distance
          variant_indicator = variant.send(:net_length)
          if variant_indicator.value.to_f != 0.0
            population_value = (measure.to_f(variant_indicator.unit.to_sym) / variant_indicator.value.to_f).in(variant_indicator.unit.to_sym)
          else
            raise "No way to divide by zero : variant indicator value is #{variant_indicator.inspect}"
          end
        elsif measure.dimension == :none
          population_value = value.in(:unity)
        else
          w.warn "Bad unit: #{unit} for intervention"
        end
        # case population
      end
      if working_area && working_area.to_d(:square_meter) > 0.0 && unit_target_dose
        w.info " Working area : #{working_area.inspect.green}"
        w.info " Variant indicator : #{variant_indicator.inspect.green}"
        w.info " Population value : #{population_value.inspect.red}"
        global_intrant_value = population_value.to_d * working_area.to_d(unit_target_dose.to_sym)
        return global_intrant_value
      else
        return population_value
      end
    end

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
    def find_or_create_product(input, name, nature, _unit, at, variety = nil)
      # Load hash to transcode EDI input/output to nature
      here = Pathname.new(__FILE__).dirname

      inputs_transcode = {}.with_indifferent_access
      if here.join('inputs.csv').exist?
        CSV.foreach(here.join('inputs.csv'), headers: true) do |row|
          inputs_transcode[row[0]] = row[1].to_sym
        end
      end

      variant = ProductNatureVariant.where(name: name, active: true).first
      w.info "Variant exist - input name : #{input.input_name}".inspect.red if variant

      unless variant

        variant = ProductNatureVariant.import_from_nomenclature(inputs_transcode[nature], force = true)
        variant.name = name
        variant.save!

        w.info "Variant creation - Variant : #{variant.name}".inspect.red

        # default_indicators = {
        # net_mass: Measure.new(1.00, :kilogram),
        # net_volume: Measure.new(1.00, :liter)
        # }.with_indifferent_access

        # default_indicators.each do |indicator_name, value|
        #  variant.read! indicator_name, value
        # end
        # w.info "Indicators OK - Variant : #{variant.name}".inspect.red

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

        # for seed intrant
        if inputs_transcode[nature] == :seed && variety
          matter.derivative_of = variety
          matter.save!
        end

        w.info "Variant creation with product - Matter : #{matter.name}".inspect.red
        return matter

      end
    end

    def record_default_intervention(i, target, procedure, intervention_input_attributes = {})
      ## START && STOP
      start = i.intervention_started_at
      stop = i.intervention_stopped_at if i.intervention_stopped_at.present?
      stop ||= start
      info = "#{i.intervention_name} | #{i.intervention_guid}"

      # build base procedure
      attributes = {
        procedure_name: procedure.name,
        actions: procedure.mandatory_actions.map(&:name),
        description: info
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

      working_zone_area = target.shape.area.in(:square_meter).convert(:hectare)
      w.info "working_zone_area : #{working_zone_area}".inspect.yellow

      ## DURATION
      # get duration from EDI DAPLOS file
      if i.intervention_duration.present? && !(i.intervention_duration.match /^0+$/)
        # TODO: with format #JJHHMM ex : 010430 => 01 day 4 hour 30 minute
        j = Measure.new(i.intervention_duration[0, 2].to_i, :day).convert(:second)
        h = Measure.new(i.intervention_duration[2, 2].to_i, :hour).convert(:second)
        s = Measure.new(i.intervention_duration[4, 2].to_i, :minute).convert(:second)
        duration = j + h + s
        stopped_at = Date.parse(start).to_time + catalog_duration.to_f.seconds
        w.info "duration from EDI DAPLOS : #{duration}".inspect.red
      # or compute from lexicon flow reference
      elsif flow = MasterEquipmentFlow.find_by(procedure_name: procedure.name)
        if flow && working_zone_area.to_f > 0.0
          duration = (flow.intervention_flow.to_d * working_zone_area.to_d * 3600).in(:second)
          stopped_at = Date.parse(start).to_time + duration.to_f.seconds
        end
        w.info "duration from flow reference : #{duration}".inspect.red
      # or set 1 min duration
      else
        duration = 61
        stopped_at = Date.parse(stop).to_time + duration.to_f.seconds
      end
      ## working_periods
      attributes[:working_periods_attributes] = {
        '0' => {
          started_at: Date.parse(start).strftime('%Y-%m-%d %H:%M'),
          stopped_at: stopped_at.strftime('%Y-%m-%d %H:%M'),
          working_duration: duration
        }
      }

      ## inputs
      updaters = []

      input_attributes = []
      i.inputs.each_with_index do |actor, index|
        p = find_or_create_product(actor, actor.input_name, actor.input_nature_edicode, actor.input_unity_edicode, Date.parse(start).to_time)

        units_transcode = { 'KGM' => :kilogram, 'LTR' => :liter, 'TNE' => :ton, 'NAR' => :unity }
        unit = Nomen::Unit.find(units_transcode[actor.input_unity_edicode])

        w.info "product : #{p.name}".inspect.yellow

        procedure.parameters_of_type(:input).each do |input|
          w.info "quantity value : #{actor.input_quantity_per_hectare.to_f}".inspect.yellow

          # find measure from quantity
          if actor.input_quantity
            product_measure = population_conversion(p, actor.input_quantity, unit.name)
          elsif actor.input_quantity.blank? && actor.input_quantity_per_hectare
            product_measure_conversion = measure_conversion(actor.input_quantity_per_hectare.to_f, unit.name, :hectare)
            product_measure = population_conversion(p, product_measure_conversion.value, product_measure_conversion.unit)
          end

          w.info "product_measure : #{product_measure}".inspect.yellow
          # find best handler for product measure
          i = input.best_handler_for(product_measure)
          handler = if i.is_a?(Array)
                      input.best_handler_for(product_measure).first
                    else
                      input.best_handler_for(product_measure)
                    end
          w.info "handler : #{handler}".inspect.yellow

          value_for_input = product_measure.convert(handler.unit.name.to_sym)

          # puts "input : #{input}".inspect.red
          # puts "input filter : #{input.filter}".inspect.green
          next unless p.of_expression(input.filter)

          w.info "quantity value per hectare : #{actor.input_quantity_per_hectare.to_f}".inspect.yellow

          attributes[:inputs_attributes] ||= {}
          attributes[:inputs_attributes][index.to_s] = {
            reference_name: input.name,
            product_id: p.id,
            quantity_handler: handler.name,
            quantity_value: value_for_input.to_f
          }

          input_attributes << {
            reference_name: input.name,
            product_id: p.id,
            area_quantity: actor.input_quantity_per_hectare.to_f,
            quantity: value_for_input.to_f
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
      w.info intervention.inspect.yellow
      intervention_attributes = intervention.to_attributes
      matching_interventions = ::Intervention.where(id:
          InterventionWorkingPeriod.where(intervention_attributes[:working_periods_attributes]['0'].slice(:started_at))
          .select(:id))
      interventions_with_matching_inputs = intervention_input_attributes.select do |_id, inputs|
        inputs.map { |h| h.except(:quantity) } == input_attributes.map { |h| h.except(:quantity) }
      end
      matching_interventions = matching_interventions.where(id: interventions_with_matching_inputs.keys)
      existing_intervention = matching_interventions.find_by(
        procedure_name: intervention_attributes[:procedure_name]
      )
      if existing_intervention
        existing_intervention.targets.create!(intervention_attributes[:targets_attributes]['0'])
        existing_intervention.inputs.each do |input|
          new_input = input_attributes.find { |i| i[:reference_name].to_s == input.reference_name && i[:product_id] == input.product_id }
          # byebug unless new_input
          input.quantity_value += new_input[:quantity]
          input.save!
        end
      else
        existing_intervention = ::Intervention.create!(intervention.to_attributes)
      end
      intervention_input_attributes[existing_intervention.id] = input_attributes
      existing_intervention
    end

    def record_complex_intervention(i, target, procedure)
      start = i.intervention_started_at
      stop = i.intervention_stopped_at if i.intervention_stopped_at.present?
      stop ||= start
      info = "#{i.intervention_name} | #{i.intervention_guid}"

      # build base procedure
      attributes = {
        procedure_name: procedure.name,
        actions: procedure.mandatory_actions.map(&:name),
        description: info
      }

      working_zone_area = target.shape.area.in(:square_meter).convert(:hectare)
      w.info "working_zone_area : #{working_zone_area}".inspect.yellow

      ## DURATION
      # get duration from EDI DAPLOS file
      if i.intervention_duration.present? && !(i.intervention_duration.match /^0+$/)
        # TODO: with format #JJHHMM ex : 010430 => 01 day 4 hour 30 minute
        j = Measure.new(i.intervention_duration[0, 2].to_i, :day).convert(:second)
        h = Measure.new(i.intervention_duration[2, 2].to_i, :hour).convert(:second)
        s = Measure.new(i.intervention_duration[4, 2].to_i, :minute).convert(:second)
        duration = j + h + s
        stopped_at = Date.parse(start).to_time + catalog_duration.to_f.seconds
        w.info "duration from EDI DAPLOS : #{duration}".inspect.red
      # or compute from lexicon flow reference
      elsif flow = MasterEquipmentFlow.find_by(procedure_name: procedure.name)
        if flow && working_zone_area.to_f > 0.0
          duration = (flow.intervention_flow.to_d * working_zone_area.to_d * 3600).in(:second)
          stopped_at = Date.parse(start).to_time + duration.to_f.seconds
        end
        w.info "duration from flow reference : #{duration}".inspect.red
      # or set 1 min duration
      else
        duration = 61
        stopped_at = Date.parse(stop).to_time + duration.to_f.seconds
      end
      ## working_periods
      attributes[:working_periods_attributes] = {
        '0' => {
          started_at: Date.parse(start).strftime('%Y-%m-%d %H:%M'),
          stopped_at: stopped_at.strftime('%Y-%m-%d %H:%M'),
          working_duration: duration
        }
      }

      target_variety = target.activity_production.cultivation_variety

      ###############################
      ####  SOWING / IMPLANTING  ####
      ###############################

      if procedure.name.to_s == 'sowing_without_plant_output'

        ## inputs
        updaters = []

        if i.inputs.any?
          i.inputs.each_with_index do |actor, index|
            p = find_or_create_product(actor, actor.input_name, actor.input_nature_edicode, actor.input_unity_edicode, Date.parse(start).to_time)

            units_transcode = { 'KGM' => :kilogram, 'LTR' => :liter, 'TNE' => :ton, 'NAR' => :unity }
            unit = Nomen::Unit.find(units_transcode[actor.input_unity_edicode])

            w.info "product : #{p.name}".inspect.yellow

            procedure.parameters_of_type(:input).each do |input|
              w.info "quantity value : #{actor.input_quantity_per_hectare.to_f}".inspect.yellow
              # find measure from quantity
              if actor.input_quantity
                product_measure = population_conversion(p, actor.input_quantity, unit.name)
              elsif actor.input_quantity.blank? && actor.input_quantity_per_hectare
                product_measure_conversion = measure_conversion(actor.input_quantity_per_hectare.to_f, unit.name, :hectare)
                product_measure = population_conversion(p, product_measure_conversion.value, product_measure_conversion.unit)
              end
              w.info "product_measure : #{product_measure}".inspect.yellow
              # find best handler for product measure
              i = input.best_handler_for(product_measure)
              handler = if i.is_a?(Array)
                          input.best_handler_for(product_measure).first
                        else
                          input.best_handler_for(product_measure)
                        end
              w.info "handler : #{handler}".inspect.yellow

              value_for_input = product_measure.convert(handler.unit.name.to_sym)

              # puts "input : #{input}".inspect.red
              # puts "input filter : #{input.filter}".inspect.green
              next unless p.of_expression(input.filter)

              w.info "quantity value per hectare : #{actor.input_quantity_per_hectare.to_f}".inspect.yellow

              attributes[:inputs_attributes] ||= {}
              attributes[:inputs_attributes][index.to_s] = {
                reference_name: input.name,
                product_id: p.id,
                quantity_handler: handler.name,
                quantity_value: value_for_input.to_f
              }

              # puts "inputs attributes #{attributes}".inspect.yellow

              updaters << "inputs[#{index}]quantity_value"
              break
            end
          end
        else
          attributes[:inputs_attributes] ||= {}
        end

        ## group (zone)
        # target
        # output r.target_variant
        w.debug target.inspect
        # w.debug procedure.parameters_of_type(:group).inspect.red

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

        ## tools
        attributes[:tools_attributes] ||= {}

        ## doers
        attributes[:doers_attributes] ||= {}

        # # impact
        intervention = Procedo::Engine.new_intervention(attributes)
        updaters.reverse.each do |updater|
          intervention.impact_with!(updater)
        end

        w.debug 'SOWING'.inspect.red

        ## save
        intervention = ::Intervention.create!(intervention.to_attributes)

      ###############################
      ####  HARVESTING           ####
      ###############################

      elsif procedure.name.to_s == 'harvesting'

        # find all plants in the current target
        # plant = find_plants(support: target, variety: target_variety, at: start).first

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

        ## outputs
        updaters = []

        i.outputs.each_with_index do |actor, index|
          w.debug "actor : #{actor}".inspect.red

          # compute output name
          output_nature_agroedi = RegisteredAgroediCode.where(repository_id: 15, reference_code: actor.output_nature_edicode).first
          w.debug "nature agroedi : #{output_nature_agroedi}".inspect.yellow
          output_specie_agroedi = RegisteredAgroediCode.where(repository_id: 18, reference_code: actor.output_specie_edicode).first
          w.debug "specie agroedi : #{output_specie_agroedi}".inspect.yellow
          output_nature_transcode = { 'ZJI' => :straw, 'ZJH' => :grain, 'W80' => :grape, 'W79' => :grape, 'W78' => :grape }

          output_name = "#{actor.output_name} | #{output_nature_agroedi.reference_label}"
          w.debug "output_name : #{output_name}".inspect.red

          # find or import variant
          output_variant = ProductNatureVariant.find_by(name: output_name, derivative_of: target_variety)
          unless output_variant
            output_variant = ProductNatureVariant.find_or_import!(output_nature_transcode[output_nature_agroedi.reference_code], derivative_of: target_variety).first
            output_variant ||= ProductNatureVariant.import_from_nomenclature(output_nature_transcode[output_nature_agroedi.reference_code], force: true)
            output_variant.name = output_name
            output_variant.derivative_of = target_variety
            output_variant.save!
          end

          w.debug "variant name : #{output_variant.name}".inspect.green

          units_transcode = { 'KGM' => :kilogram, 'LTR' => :liter, 'TNE' => :ton, 'NAR' => :unity }
          # in AgroEDI, yield is in ZHK = ton_per_hectare only
          yield_per_hectare = Measure.new(actor.output_yield.to_f, :ton_per_hectare)

          procedure.parameters_of_type(:output).each do |output|
            # compute measure from quantity
            product_measure = Measure.new(actor.output_quantity.to_f, units_transcode[actor.output_unity_edicode])
            # find best handler for product measure
            i = output.best_handler_for(product_measure)
            handler = if i.is_a?(Array)
                        output.best_handler_for(product_measure).first.name
                      else
                        output.best_handler_for(product_measure).name
                      end
            next unless output_variant.of_expression(output.filter)
            attributes[:outputs_attributes] ||= {}
            attributes[:outputs_attributes][index.to_s] = { reference_name: output.name, variant_id: output_variant.id, new_name: output_name, quantity_handler: handler, quantity_value: product_measure.to_f }
            updaters << "outputs[#{index}]quantity_value"
            break
          end
        end

        ## tools
        attributes[:tools_attributes] ||= {}

        ## doers
        attributes[:doers_attributes] ||= {}

        # # impact
        intervention = Procedo::Engine.new_intervention(attributes)
        updaters.each do |updater|
          intervention.impact_with!(updater)
        end

        w.debug 'HARVESTING'.inspect.red

        ## save
        intervention = ::Intervention.create!(intervention.to_attributes)
      else
        w.debug 'Problem to recognize intervention and create it ' + procedure.name.inspect
      end

      intervention
    end
  end
end
