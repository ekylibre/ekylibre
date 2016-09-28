# coding: utf-8
module Ekylibre
  class InterventionsExchanger < ActiveExchanger::Base
    def check
      rows = CSV.read(file, headers: true, col_sep: ';').delete_if { |r| r[0].blank? }.sort { |a, b| [a[2].split(/\D/).reverse.join, a[0]] <=> [b[2].split(/\D/).reverse.join, b[0]] }
      valid = true
      w.count = rows.size
      rows.each_with_index do |row, index|
        line_number = index + 2
        prompt = "L#{line_number.to_s.yellow}"
        r = parse_row(row)
        if row[0].blank?
          w.info "#{prompt} Skipped"
          next
        end
        # info, warn, error
        # valid = false if error

        # PROCEDURE EXIST IN NOMENCLATURE
        #
        if r.procedure_name.blank?
          w.error "#{prompt} No procedure given"
          valid = false
        end
        # procedure_long_name = 'base-' + r.procedure_name.to_s + '-0'
        # procedure_nomen = Procedo[procedure_long_name]
        # unless procedure_nomen
        #  w.error "#{prompt} Invalid procedure name (#{r.procedure_name})"
        #  valid = false
        # end

        # PROCEDURE HAVE A DURATION
        #
        unless r.intervention_duration_in_hour.hours && r.intervention_duration_in_hour.hours.to_f > 0.0
          w.error "#{prompt} Need a duration > 0"
          valid = false
        end

        # PROCEDURE GIVE A CAMPAIGN WHO DOES NOT EXIST IN DB
        #
        unless campaign = Campaign.find_by_name(r.campaign_code)
          w.warn "#{prompt} #{r.campaign_code} will be created as a campaign"
        end

        # PROCEDURE GIVE SUPPORTS CODES BUT NOT EXIST IN DB
        #
        if r.support_codes
          supports = Product.where(work_number: r.support_codes)
          supports ||= CultivableZone.where(work_number: r.support_codes)
          unless supports
            w.warn "#{prompt} #{r.support_codes} does not exist in DB"
            w.warn "#{prompt} a standard activity will be set"
          end
        end

        # PROCEDURE GIVE VARIANT OR VARIETY CODES BUT NOT EXIST IN DB OR IN NOMENCLATURE
        #
        if r.target_variety
          unless Nomen::Variety.find(r.target_variety)
            w.error "#{prompt} #{r.target_variety} does not exist in NOMENCLATURE"
            valid = false
          end
        end
        if r.target_variant
          unless r.target_variant.is_a? ProductNatureVariant
            w.error "#{prompt} Invalid target variant: #{r.target_variant.inspect}"
            valid = false
          end
        end

        # PROCEDURE GIVE EQUIPMENTS CODES BUT NOT EXIST IN DB
        #
        if r.equipment_codes
          unless equipments = Equipment.where(work_number: r.equipment_codes)
            w.warn "#{prompt} #{r.equipment_codes} does not exist in DB"
          end
        end

        # PROCEDURE GIVE WORKERS CODES BUT NOT EXIST IN DB
        #
        if r.worker_codes
          unless workers = Worker.where(work_number: r.worker_codes)
            w.warn "#{prompt} #{r.worker_codes} does not exist in DB"
          end
        end

        # CHECK ACTORS
        #
        [r.first, r.second, r.third].each_with_index do |actor, i|
          next if actor.product_code.blank?

          # PROCEDURE GIVE PRODUCTS OR VARIANTS BUT NOT EXIST IN DB
          #
          if actor.product.is_a?(Product)
            valid = true
          # w.info "#{prompt} Actor ##{i + 1} exist in DB as a product (#{actor.product.name})"
          elsif actor.variant.is_a?(ProductNatureVariant)
            valid = true
          # w.info "#{prompt} Actor ##{i + 1} exist in DB as a variant (#{actor.variant.name})"
          elsif item = Nomen::ProductNatureVariants.find(actor.target_variant)
            valid = true
          # w.info "#{prompt} Actor ##{i + 1} exist in NOMENCLATURE as a variant (#{item.name})"
          else
            w.error "#{prompt} Actor ##{i + 1} (#{actor.product_code}) does not exist in DB as a product or as a variant in DB or NOMENCLATURE"
            valid = false
          end

          # PROCEDURE GIVE PRODUCTS OR VARIANTS BUT NOT EXIST IN DB
          #
          unit_name = actor.input_unit_name
          if Nomen::Units[unit_name]
            valid = true
          # w.info "#{prompt} #{unit_name} exist in NOMENCLATURE as a unit"
          elsif u = Nomen::Units.find_by(symbol: unit_name)
            valid = true
          # w.info "#{prompt} #{unit_name} exist in NOMENCLATURE as a symbol of #{u.name}"
          else
            w.error "#{prompt} Unknown unit: #{unit_name.inspect}"
            valid = false
          end
        end
      end
      valid
    end

    def import
      rows = CSV.read(file, headers: true, col_sep: ';').delete_if { |r| r[0].blank? }.sort { |a, b| [a[2].split(/\D/).reverse.join, a[0]] <=> [b[2].split(/\D/).reverse.join, b[0]] }
      w.count = rows.size

      information_import_context = "Import Ekylibre interventions on #{Time.zone.now.l}"

      # Load hash to transcode old procedure
      # transcode procedure_name from old procedure
      here = Pathname.new(__FILE__).dirname
      procedures_transcode = {}.with_indifferent_access
      CSV.foreach(here.join('procedures.csv'), headers: true) do |row|
        procedures_transcode[row[0]] = row[1].to_sym
      end

      rows.each_with_index do |row, _index|
        line_number = _index + 2
        r = parse_row(row)

        # Check duration
        if r.intervention_duration_in_hour.hours
          r.intervention_stopped_at = r.intervention_started_at + r.intervention_duration_in_hour.hours
        else
          w.warn "Need a duration for intervention ##{r.intervention_number}"
          raise "Need a duration for intervention ##{r.intervention_number}"
        end

        w.debug r.supports.inspect.red

        # Get supports
        # Supports are Product : LandParcel, Plant, Animal...link to Campaign and ActivityProduction
        r.production_supports = []
        # Case A
        if r.supports.any?
          # find all supports who match : cultivation_variety / cultivation_variant or just storage given
          # a same cultivable zone could be a support of many productions
          # ex : corn_crop, zea_mays_lg452, ZC42 have to return all supports with corn_crop of variety zea_mays_lg452 in ZC42
          p_ids = []
          for product in r.supports
            # case A1 : CZ
            if product.is_a?(CultivableZone)
              ap = ActivityProduction.of_campaign(r.campaign).where(cultivable_zone: product)
              ap = ap.of_cultivation_variety(r.target_variety) if r.target_variety
              ps = ap.map(&:support)
            # case A2 : Product
            elsif product.is_a?(Product)
              ps = [product]
            end
            p_ids << ps.map(&:id)
          end
          w.debug p_ids.inspect.blue
          supports = Product.find(p_ids)
        # r.production_supports = ActivityProduction.of_campaign(r.campaign).find(ps_ids)
        # Case B
        elsif r.support_codes.present?
          activity = Activity.where(family: r.support_codes.flatten.first.downcase.to_sym).first
          production = Production.where(activity: activity, campaign: r.campaign).first if activity && r.campaign
        # Case C
        else
          activity = Activity.where(nature: :auxiliary, with_supports: false, with_cultivation: false).first
          production = Production.where(activity: activity, campaign: r.campaign).first if activity && r.campaign
        end

        w.debug supports.inspect.yellow

        raise "stop #{r.target_variety}" unless supports.any?

        # case 1 supports exists
        if supports.any?
          # w.info r.to_h.to_yaml
          w.info "----------- L#{line_number.to_s.yellow} : #{r.intervention_number} / #{supports.map(&:name).to_sentence} -----------".blue
          w.info ' procedure : ' + r.procedure_name.inspect.green
          w.info ' started_at : ' + r.intervention_started_at.inspect.yellow if r.intervention_started_at
          w.info ' first product : ' + r.first.product.name.inspect.red if r.first.product
          w.info ' first product quantity : ' + r.first.product.input_population.to_s + ' ' + r.first.product.input_unit_name.to_s.inspect.red if r.first.product_input_population
          w.info ' second product : ' + r.second.product.name.inspect.red if r.second.product
          w.info ' third product : ' + r.third.product.name.inspect.red if r.third.product
          w.info ' target variety : ' + r.target_variety.inspect.yellow if r.target_variety
          w.info ' supports : ' + supports.map(&:name).to_sentence.inspect.yellow if supports
          w.info ' workers_name : ' + r.workers.map(&:name).inspect.yellow if r.workers
          w.info ' equipments_name : ' + r.equipments.map(&:name).inspect.yellow if r.equipments

          # plants = find_plants(support: support, variety: r.target_variety, at: r.intervention_started_at)
          # w.info ' #{plants.count} plants : ' + plants.map(&:name).inspect.yellow if plants
          targets = supports

          intervention = qualify_intervention(r, targets, procedures_transcode)
        # intervention = send("record_#{r.procedure_name}", r, targets)
        else
          w.warn "Cannot add intervention #{r.intervention_number} without support"
        end

        if intervention
          intervention.description ||= ''
          intervention.description += ' - ' + information_import_context + ' - N° : ' + r.intervention_number.to_s
          intervention.save!
          w.info "Intervention n°#{intervention.id} - #{intervention.name} has been created".green
        else
          w.warn 'Intervention is in a black hole'.red
        end

        w.check_point
      end
    end

    protected

    # convert measure to variant unit and divide by variant_indicator
    def measure_conversion(_product, population, unit, unit_target_dose)
      value = population
      w.debug value.inspect.yellow
      nomen_unit = nil
      # concat units if needed
      if unit.present? && unit_target_dose.present?
        u = unit + '_per_' + unit_target_dose
      elsif unit.present?
        u = unit
      end
      # case units are symbol
      if u && !Nomen::Units[u]
        if u = Nomen::Units.find_by(symbol: u)
          u = u.name.to_s
        else
          raise ActiveExchanger::NotWellFormedFileError, "Unknown unit #{u.inspect}."
        end
      end
      u = u.to_sym if u
      nomen_unit = Nomen::Units[u] if u
      if value >= 0.0 && nomen_unit
        measure = Measure.new(value, u)
        return measure
      else
        return nil
      end
    end

    # convert measure to variant unit and divide by variant_indicator
    # ex : for a wheat_seed_25kg
    # 182.25 kilogram (converting in kilogram) / 25.00 kilogram
    def population_conversion(product, population, unit, unit_target_dose, working_area = 0.0.square_meter)
      w.info "Method population_conversion - population : #{population.inspect}"
      w.info "Method population_conversion - unit : #{unit.inspect}"
      w.info "Method population_conversion - unit_target_dose : #{unit_target_dose.inspect}"
      if product.is_a?(Product)
        variant = product.variant
      elsif product.is_a?(ProductNatureVariant)
        variant = product
      end
      value = population
      nomen_unit = nil
      # convert symbol into unit if needed
      if unit.present? && !Nomen::Units[unit]
        if u = Nomen::Units.find_by(symbol: unit)
          unit = u.name.to_s
        else
          raise ActiveExchanger::NotWellFormedFileError, "Unknown unit #{unit.inspect} for variant #{item_variant.name.inspect}."
        end
      end
      unit = unit.to_sym if unit
      nomen_unit = Nomen::Units[unit] if unit
      #
      w.debug value.inspect.yellow
      if value >= 0.0 && nomen_unit
        measure = Measure.new(value, unit)
        w.info "Method population_conversion - measure : #{measure.inspect.yellow}"
        w.info "Method population_conversion - variant : #{variant.name.inspect.yellow}"
        if measure.dimension == :volume
          variant_indicator = variant.send(:net_volume)
          if variant_indicator.value.to_f != 0.0
            population_value = (measure.to_f(variant_indicator.unit.to_sym) / variant_indicator.value.to_f)
          else
            raise "No way to divide by zero : variant indicator value is #{variant_indicator.inspect}"
          end
        elsif measure.dimension == :mass
          variant_indicator = variant.send(:net_mass)
          if variant_indicator.value.to_f != 0.0
            population_value = (measure.to_f(variant_indicator.unit.to_sym) / variant_indicator.value.to_f)
          else
            raise "No way to divide by zero : variant indicator value is #{variant_indicator.inspect}"
          end
        elsif measure.dimension == :distance
          variant_indicator = variant.send(:net_length)
          if variant_indicator.value.to_f != 0.0
            population_value = (measure.to_f(variant_indicator.unit.to_sym) / variant_indicator.value.to_f)
          else
            raise "No way to divide by zero : variant indicator value is #{variant_indicator.inspect}"
          end
        elsif measure.dimension == :none
          population_value = value
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

    # shortcut to call population_conversion function
    def actor_population_conversion(actor, working_measure)
      population_conversion((actor.product.present? ? actor.product : actor.variant), actor.input_population, actor.input_unit_name, actor.input_unit_target_dose, working_measure)
    end

    # shortcut to call population_conversion function
    def actor_measure_conversion(actor)
      measure_conversion((actor.product.present? ? actor.product : actor.variant), actor.input_population, actor.input_unit_name, actor.input_unit_target_dose)
    end

    # Parse a row of the current file using this reference:
    #
    #  0 "ID intervention"
    #  1 "campagne"
    #  2 "date debut intervention"
    #  3 "heure debut intervention"
    #  4 "durée (heure)"
    #  5 "procedure reference_name CF NOMENCLATURE"
    #  6 "description"
    #  7 "codes des supports travaillés [array] CF WORK_NUMBER"
    #  8 "variant de la cible (target) CF NOMENCLATURE"
    #  9 "variété de la cible (target) CF NOMENCLATURE"
    # 10 "codes des equipiers [array] CF WORK_NUMBER"
    # 11 "codes des equipments [array] CF WORK_NUMBER"
    # --
    # INTRANT 1
    # 12 "code intrant CF WORK_NUMBER"
    # 13 "quantité intrant"
    # 14 "unité intrant CF NOMENCLATURE"
    # 15 "diviseur de l'intrant si dose CF NOMENCLATURE"
    # --
    # INTRANT 2
    # 16 "code intrant CF WORK_NUMBER"
    # 17 "quantité intrant"
    # 18 "unité intrant CF NOMENCLATURE"
    # 19 "diviseur de l'intrant si dose CF NOMENCLATURE"
    # --
    # INTRANT 3
    # 20 "code intrant CF WORK_NUMBER"
    # 21 "quantité intrant"
    # 22 "unité intrant CF NOMENCLATURE"
    # 23 "diviseur de l'intrant si dose CF NOMENCLATURE"
    # --
    #
    # @FIXME: Translations in english please
    def parse_row(row)
      r = OpenStruct.new(
        intervention_number: row[0].to_i,
        campaign_code: row[1].to_s,
        intervention_started_at: (row[2].blank? || row[3].blank? ? nil : Time.strptime(Date.parse(row[2].to_s).strftime('%d/%m/%Y') + ' ' + row[3].to_s, '%d/%m/%Y %H:%M')),
        intervention_duration_in_hour: (row[4].blank? ? nil : row[4].tr(',', '.').to_d),
        procedure_name: (row[5].blank? ? nil : row[5].to_s.downcase.to_sym), # to transcode
        procedure_description: row[6].to_s,
        support_codes: (row[7].blank? ? nil : row[7].to_s.strip.upcase.split(/\s*\,\s*/)),
        target_variant: (row[8].blank? ? nil : row[8].to_s.downcase.to_sym),
        target_variety: (row[9].blank? ? nil : row[9].to_s.downcase.to_sym),
        worker_codes: row[10].to_s.strip.upcase.split(/\s*\,\s*/),
        equipment_codes: row[11].to_s.strip.upcase.split(/\s*\,\s*/),
        ### FIRST PRODUCT
        first: parse_actor(row, 12),
        ### SECOND PRODUCT
        second: parse_actor(row, 16),
        ### THIRD PRODUCT
        third: parse_actor(row, 20),
        indicators: row[24].blank? ? {} : row[24].to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).collect { |i| i.split(/[[:space:]]*(\:|\=)[[:space:]]*/) }.each_with_object({}) do |i, h|
          h[i.first.strip.downcase.to_sym] = i.third
          h
        end
      )
      # Get campaign
      unless r.campaign = Campaign.find_by_name(r.campaign_code)
        r.campaign = Campaign.create!(name: r.campaign_code, harvest_year: r.campaign_code)
      end
      # Get supports
      w.debug "Support code in method parse_row #{r.support_codes}".inspect.green
      r.supports = parse_record_list(r.support_codes, CultivableZone, :work_number)
      r.supports ||= parse_record_list(r.support_codes.delete_if { |s| %w(EXPLOITATION).include?(s) }, Product, :work_number)
      w.debug "Support code in method parse_record list #{r.supports.map(&:name)}".inspect.green
      # Get equipments
      r.equipments = parse_record_list(r.equipment_codes, Equipment, :work_number)
      # Get workers
      r.workers = parse_record_list(r.worker_codes, Worker, :work_number)
      # Get target_variant
      target_variant = nil
      if r.target_variety && !r.target_variant
        target_variant = ProductNatureVariant.find_or_import!(r.target_variety).first
      end
      if target_variant.nil? && r.target_variant
        unless target_variant = ProductNatureVariant.find_by(work_number: r.target_variant)
          target_variant = ProductNatureVariant.import_from_nomenclature(r.target_variant)
        end
      end
      r.target_variant = target_variant
      r
    end

    # parse an actor of a current row
    def parse_actor(row, index)
      a = OpenStruct.new(
        product_code: (row[index].blank? ? nil : row[index].to_s.upcase),
        input_population: (row[index + 1].blank? ? nil : row[index + 1].tr(',', '.').to_d),
        input_unit_name: (row[index + 2].blank? ? nil : row[index + 2].to_s.downcase),
        input_unit_target_dose: (row[index + 3].blank? ? nil : row[index + 3].to_s.downcase)
      )
      if a.product_code
        a.variant = if a.product = Product.find_by_work_number(a.product_code)
                      a.product.variant
                    else
                      ProductNatureVariant.find_by_work_number(a.product_code)
                    end
      end
      a
    end

    def parse_record_list(list, klass, column)
      unfound = []
      records = list.collect do |c|
        record = klass.find_by(column => c)
        unfound << c unless record
        record
      end
      if unfound.any?
        raise "Cannot find #{klass.name.tableize.humanize} with #{column}: #{unfound.to_sentence}"
      end
      records
    end

    # find the best plant for the current support and cultivable zone by variety or variant
    def find_best_plant(options = {})
      plant = nil
      if options[:support] && options[:support].storage && options[:support].storage.shape
        # try to find the current plant on cultivable zone if exist
        cultivable_zone_shape = Charta.new_geometry(options[:support].storage.shape)
        if cultivable_zone_shape && product_around = Plant.within_shape(cultivable_zone_shape)
          plant = Plant.where(id: product_around.map(&:id)).availables.first
        end
      end
      if options[:variety] && options[:at]
        members = options[:support].storage.contains(options[:variety], options[:at])
        plant = Plant.where(id: members.map(&:product_id)).availables.first if members
      elsif options[:variant] && options[:at]
        members = options[:support].storage.localized_variants(options[:variant], at: options[:at])
        plant = Plant.where(id: members.map(&:product_id)).availables.first if members
      end
      plant
    end

    # find all plants for the current support and cultivable zone by variety or variant
    def find_plants(options = {})
      plants = nil
      if options[:support]
        w.debug "supports for finding plant : #{options[:support]}".inspect.blue
        plant_ids = []
        options[:support].each do |support|
          # try to find the current plants on cultivable zone if exists
          support_shape = Charta.new_geometry(support.shape)
          w.debug "support_shape : #{support_shape.to_geojson}".to_s.red
          w.debug "plant count : #{Plant.count}".red
          w.debug "plant count : #{Plant.pluck(:name).to_sentence}".white
          product_around = Plant.shape_within(support_shape)
          w.debug "product_around : #{product_around}".inspect.blue
          if product_around.any?
            plant_ids << Plant.where(id: product_around.map(&:id)).pluck(:id)
          end
        end
        plants = Plant.where(id: plant_ids.compact)
      end
      if plants && options[:variety] && options[:at]
        plants = plants.of_variety(options[:variety])
      elsif options[:variant] && options[:at]
        plants = plants.where(variant: options[:variant])
      end
      plants
    end

    # find the working area by finding plant area for the current support and cultivable zone by variety or variant
    def find_plant_working_area(options = {})
      area = nil
      if options[:variety] && options[:at]
        members = options[:support].storage.contains(options[:variety], options[:at])
        plant = Plant.where(id: members.map(&:product_id)).availables if members
        area = plant.map(&:shape_area).compact.sum if plant
      elsif options[:variant] && options[:at]
        members = options[:support].storage.localized_variants(options[:variant], at: options[:at])
        plant = Plant.where(id: members.map(&:product_id)).availables if members
        area = plant.map(&:shape_area).compact.sum if plant
      end
      area
    end

    def check_indicator_presence(object, indicator, type = nil)
      nature = object.is_a?(ProductNature) ? object : object.nature
      w.debug nature.indicators.inspect.red
      unless nature.indicators.include?(indicator)
        type ||= :frozen if object.is_a?(ProductNatureVariant)
        if type == :frozen
          nature.frozen_indicators_list << indicator
        else
          nature.variable_indicators_list << indicator
        end
        nature.save!
      end
    end

    ##################################
    #### INTERVENTIONS            ####
    ##################################

    def qualify_intervention(r, targets, procedures_transcode)
      # retrieve procedure from its name and set basics attributes
      procedure = Procedo.find(procedures_transcode[r.procedure_name])
      procedure ||= Procedo.find(r.procedure_name)

      # check if procedure is simple or not (with group parameter or output)
      if procedure.parameters.detect do |parameter|
           parameter.is_a?(Procedo::Procedure::GroupParameter) ||
           (parameter.is_a?(Procedo::Procedure::ProductParameter) && parameter.output?)
         end
        return record_complex_intervention(r, targets, procedure)
      else
        return record_default_intervention(r, targets, procedure)
      end
    end

    def record_default_intervention(r, targets, procedure)
      # build base procedure
      attributes = {
        procedure_name: procedure.name,
        actions: procedure.mandatory_actions.map(&:name),
        description: r.description
      }

      ## working_periods
      attributes[:working_periods_attributes] = {
        '0' => {
          started_at: r.intervention_started_at.strftime('%Y-%m-%d %H:%M'),
          stopped_at: r.intervention_stopped_at.strftime('%Y-%m-%d %H:%M')
        }
      }

      w.debug "targets : #{targets.map(&:name)}".inspect.yellow

      ## targets
      targets.each_with_index do |target, index|
        procedure.parameters_of_type(:target).each do |support|
          # next unless target.of_expression(support.filter)
          attributes[:targets_attributes] ||= {}
          attributes[:targets_attributes][index.to_s] = {
            reference_name: support.name,
            product_id: target.id,
            working_zone: target.shape.to_geojson
          }
          # break
        end
      end

      ## inputs
      updaters = []

      [r.first, r.second, r.third].each_with_index do |actor, index|
        next if actor.product.nil?
        procedure.parameters_of_type(:input).each do |input|
          # find measure from quantity
          product_measure = actor_measure_conversion(actor)
          # find best handler for product measure
          i = input.best_handler_for(product_measure)
          handler = if i.is_a?(Array)
                      input.best_handler_for(product_measure).first.name
                    else
                      input.best_handler_for(product_measure).name
                    end
          next unless actor.product.of_expression(input.filter)
          attributes[:inputs_attributes] ||= {}
          attributes[:inputs_attributes][index.to_s] = {
            reference_name: input.name,
            product_id: actor.product.id,
            quantity_handler: handler,
            quantity_value: product_measure.to_f
          }
          updaters << "inputs[#{index}]quantity_value"
          break
        end
      end

      ## tools
      r.equipments.each_with_index do |equipment, index|
        procedure.parameters_of_type(:tool).each do |tool|
          next unless equipment.of_expression(tool.filter)
          attributes[:tools_attributes] ||= {}
          attributes[:tools_attributes][index.to_s] = {
            reference_name: tool.name,
            product_id: equipment.id
          }
          break
        end
      end

      ## doers
      r.workers.each_with_index do |worker, index|
        procedure.parameters_of_type(:doer).each do |doer|
          next unless worker.of_expression(doer.filter)
          attributes[:doers_attributes] ||= {}
          attributes[:doers_attributes][index.to_s] = {
            reference_name: doer.name,
            product_id: worker.id
          }
          break
        end
      end

      # # impact
      intervention = Procedo::Engine.new_intervention(attributes)
      updaters.each do |updater|
        intervention.impact_with!(updater)
      end

      ## save
      ::Intervention.create!(intervention.to_hash)
    end

    def record_complex_intervention(r, targets, procedure)
      ###############################
      ####  SOWING / IMPLANTING  ####
      ###############################

      if procedure.name.to_s == 'sowing'
        # build base procedure
        attributes = { procedure_name: procedure.name, actions: procedure.mandatory_actions.map(&:name), description: r.description }

        ## working_periods
        attributes[:working_periods_attributes] = { '0' => { started_at: r.intervention_started_at.strftime('%Y-%m-%d %H:%M'), stopped_at: r.intervention_stopped_at.strftime('%Y-%m-%d %H:%M') } }

        ## inputs
        updaters = []

        [r.first, r.second, r.third].each_with_index do |actor, index|
          next if actor.product.nil?
          procedure.parameters_of_type(:input).each do |input|
            # find measure from quantity
            product_measure = actor_measure_conversion(actor)
            # find best handler for product measure
            i = input.best_handler_for(product_measure)
            handler = if i.is_a?(Array)
                        input.best_handler_for(product_measure).first.name
                      else
                        input.best_handler_for(product_measure).name
                      end
            next unless actor.product.of_expression(input.filter)
            attributes[:inputs_attributes] ||= {}
            attributes[:inputs_attributes][index.to_s] = { reference_name: input.name, product_id: actor.product.id, quantity_handler: handler, quantity_value: product_measure.to_f }
            updaters << "inputs[#{index}]quantity_value"
            break
          end
        end

        ## group (zone)
        # target
        # output r.target_variant
        w.debug targets.inspect
        w.debug procedure.parameters_of_type(:group).inspect.red

        targets.each_with_index do |target, index|
          procedure.parameters_of_type(:group).each do |group|
            attributes[:group_parameters_attributes] ||= {}
            attributes[:group_parameters_attributes][index.to_s] = { reference_name: group.name }
            attributes[:group_parameters_attributes][index.to_s][:targets_attributes] ||= {}
            attributes[:group_parameters_attributes][index.to_s][:targets_attributes]['0'] = { reference_name: group.parameters_of_type(:target).first.name, product_id: target.id, working_zone: target.shape.to_geojson.to_s }
            attributes[:group_parameters_attributes][index.to_s][:outputs_attributes] ||= {}
            attributes[:group_parameters_attributes][index.to_s][:outputs_attributes]['0'] = { reference_name: group.parameters_of_type(:output).first.name, variant_id: r.target_variant, new_name: "#{r.target_variant.name} #{target.name}", readings_attributes: { shape: { indicator_name: :shape } } }
            updaters << "group_parameters[#{index}]targets[0]working_zone"
          end
        end

        ## tools
        r.equipments.each_with_index do |equipment, index|
          procedure.parameters_of_type(:tool).each do |tool|
            next unless equipment.of_expression(tool.filter)
            attributes[:tools_attributes] ||= {}
            attributes[:tools_attributes][index.to_s] = { reference_name: tool.name, product_id: equipment.id }
            break
          end
        end

        ## doers
        r.workers.each_with_index do |worker, index|
          procedure.parameters_of_type(:doer).each do |doer|
            next unless worker.of_expression(doer.filter)
            attributes[:doers_attributes] ||= {}
            attributes[:doers_attributes][index.to_s] = { reference_name: doer.name, product_id: worker.id }
            break
          end
        end

        # # impact
        intervention = Procedo::Engine.new_intervention(attributes)
        updaters.reverse.each do |updater|
          intervention.impact_with!(updater)
        end

        w.debug 'SOWING'.inspect.red

        ## save
        ::Intervention.create!(intervention.to_hash)
        w.debug "############################# #{Plant.count}".blue
        w.debug ''

      ###############################
      ####  HARVESTING           ####
      ###############################

      elsif procedure.name.to_s == 'harvesting'

        # build base procedure
        attributes = { procedure_name: procedure.name, actions: procedure.mandatory_actions.map(&:name), description: r.description }

        ## working_periods
        attributes[:working_periods_attributes] = { '0' => { started_at: r.intervention_started_at.strftime('%Y-%m-%d %H:%M'), stopped_at: r.intervention_stopped_at.strftime('%Y-%m-%d %H:%M') } }

        # find all plants in the current target
        targets = find_plants(support: targets, variety: r.target_variety, at: r.intervention_started_at)

        ## targets
        targets.each_with_index do |target, index|
          procedure.parameters_of_type(:target).each do |support|
            # next unless target.of_expression(support.filter)
            attributes[:targets_attributes] ||= {}
            attributes[:targets_attributes][index.to_s] = { reference_name: support.name, product_id: target.id, working_zone: target.shape.to_geojson }
            # break
          end
        end

        ## outputs
        updaters = []

        [r.first, r.second, r.third].each_with_index do |actor, index|
          w.debug 'actor : #{actor}'.inspect.red
          next if actor.variant.nil?
          procedure.parameters_of_type(:output).each do |output|
            # find measure from quantity
            product_measure = actor_measure_conversion(actor)
            # find best handler for product measure
            i = output.best_handler_for(product_measure)
            handler = if i.is_a?(Array)
                        output.best_handler_for(product_measure).first.name
                      else
                        output.best_handler_for(product_measure).name
                      end
            next unless actor.product.of_expression(output.filter)
            attributes[:outputs_attributes] ||= {}
            attributes[:outputs_attributes][index.to_s] = { reference_name: output.name, variant_id: actor.variant.id, new_name: actor.name, quantity_handler: handler, quantity_value: product_measure.to_f }
            updaters << "outputs[#{index}]quantity_value"
            break
          end
        end

        ## tools
        r.equipments.each_with_index do |equipment, index|
          procedure.parameters_of_type(:tool).each do |tool|
            next unless equipment.of_expression(tool.filter)
            attributes[:tools_attributes] ||= {}
            attributes[:tools_attributes][index.to_s] = { reference_name: tool.name, product_id: equipment.id }
            break
          end
        end

        ## doers
        r.workers.each_with_index do |worker, index|
          procedure.parameters_of_type(:doer).each do |doer|
            next unless worker.of_expression(doer.filter)
            attributes[:doers_attributes] ||= {}
            attributes[:doers_attributes][index.to_s] = { reference_name: doer.name, product_id: worker.id }
            break
          end
        end

        # # impact
        intervention = Procedo::Engine.new_intervention(attributes)
        updaters.each do |updater|
          intervention.impact_with!(updater)
        end

        w.debug 'HARVESTING'.inspect.red

        ## save
        ::Intervention.create!(intervention.to_hash)
      else
        w.debug 'Problem to recognize intervention and create it ' + procedure.name.inspect
      end

      #################################
      ####  ANIMAL                 ####
      #################################

      nil
    end
  end
end
