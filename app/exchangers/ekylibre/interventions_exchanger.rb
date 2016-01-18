# coding: utf-8
class Ekylibre::InterventionsExchanger < ActiveExchanger::Base
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
      procedure_long_name = 'base-' + r.procedure_name.to_s + '-0'
      procedure_nomen = Procedo[procedure_long_name]
      unless procedure_nomen
        w.error "#{prompt} Invalid procedure name (#{r.procedure_name})"
        valid = false
      end

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
        unless supports = Product.where(work_number: r.support_codes)
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
        # w.info "#{prompt} Actor ##{i + 1} exist in DB as a product (#{actor.product.name})"
        elsif actor.variant.is_a?(ProductNatureVariant)
        # w.info "#{prompt} Actor ##{i + 1} exist in DB as a variant (#{actor.variant.name})"
        elsif item = Nomen::ProductNatureVariants.find(actor.target_variant)
        # w.info "#{prompt} Actor ##{i + 1} exist in NOMENCLATURE as a variant (#{item.name})"
        else
          w.error "#{prompt} Actor ##{i + 1} (#{actor.product_code}) does not exist in DB as a product or as a variant in DB or NOMENCLATURE"
          valid = false
        end

        # PROCEDURE GIVE PRODUCTS OR VARIANTS BUT NOT EXIST IN DB
        #
        unit_name = actor.input_unit_name
        if Nomen::Units[unit_name]
        # w.info "#{prompt} #{unit_name} exist in NOMENCLATURE as a unit"
        elsif u = Nomen::Units.find_by(symbol: unit_name)
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
    rows.each_with_index do |row, _index|
      line_number = _index + 2
      r = parse_row(row)

      if r.intervention_duration_in_hour.hours
        r.intervention_stopped_at = r.intervention_started_at + r.intervention_duration_in_hour.hours
      else
        w.warn "Need a duration for intervention ##{r.intervention_number}"
        fail "Need a duration for intervention ##{r.intervention_number}"
      end

      unless r.procedure_name
        fail "Need a duration for intervention ##{r.intervention_number}"
      end

      # Get supports and existing production_supports or activity by activity family input
      r.production_supports = []
      activity = nil
      production = nil
      if r.supports.any?
        ps_ids = []
        # find all supports who match : cultivation_variety / cultivation_variant or just storage given
        # a same cultivable zone could be a support of many productions
        # ex : corn_crop, zea_mays_lg452, ZC42 have to return all supports with corn_crop of variety zea_mays_lg452 in ZC42
        for product in r.supports
          ps = nil
          ps = if r.target_variety && r.target_variant
                 ProductionSupport.of_campaign(r.campaign).of_cultivation_varieties(r.target_variety).of_cultivation_variants(r.target_variant).where(storage: product)
               elsif r.target_variety
                 ProductionSupport.of_campaign(r.campaign).of_cultivation_varieties(r.target_variety).where(storage: product)
               elsif r.target_variant
                 ProductionSupport.of_campaign(r.campaign).of_cultivation_variants(r.target_variant).where(storage: product)
               else
                 ProductionSupport.of_campaign(r.campaign).where(storage: product)
               end
          for p in ps
            ps_ids << p.id
          end
        end
        r.production_supports = ProductionSupport.of_campaign(r.campaign).find(ps_ids)
        # Get global supports area (square_meter)
        r.production_supports_area = r.production_supports.map(&:storage_shape_area).compact.sum
      elsif r.support_codes.present?
        activity = Activity.where(family: r.support_codes.flatten.first.downcase.to_sym).first
        production = Production.where(activity: activity, campaign: r.campaign).first if activity && r.campaign
      else
        activity = Activity.where(nature: :auxiliary, with_supports: false, with_cultivation: false).first
        production = Production.where(activity: activity, campaign: r.campaign).first if activity && r.campaign
      end

      # case 1 support and production find
      if r.production_supports.any?
        r.production_supports.each do |support|
          storage = support.storage
          Ekylibre::FirstRun::Booker.production = support.production
          if storage.is_a?(CultivableZone)
            area = if support.quantity_indicator == :net_surface_area && support.quantity
                     support.get(:net_surface_area).to_d(:square_meter)
                   else
                     storage.shape_area.to_d
                   end
            coeff = ((storage.shape_area / 10_000.0) / 6.0).to_d if area

            duration = (r.intervention_duration_in_hour.hours * (area / r.production_supports_area.to_d).to_d).round(2) if area

            # w.info r.to_h.to_yaml
            w.info "----------- L#{line_number.to_s.yellow} : #{r.intervention_number} / #{support.name} -----------".blue
            w.info ' procedure : ' + r.procedure_name.inspect.green
            w.info ' started_at : ' + r.intervention_started_at.inspect.yellow if r.intervention_started_at
            w.info ' first product : ' + r.first.product.name.inspect.red if r.first.product
            w.info ' first product quantity : ' + r.first.product.input_population.to_s + ' ' + r.first.product.input_unit_name.to_s.inspect.red if r.first.product_input_population
            w.info ' second product : ' + r.second.product.name.inspect.red if r.second.product
            w.info ' third product : ' + r.third.product.name.inspect.red if r.third.product
            w.info ' cultivable_zone : ' + storage.work_name.inspect.yellow if storage
            w.info ' target variety : ' + r.target_variety.inspect.yellow if r.target_variety
            w.info ' support : ' + support.work_name.inspect.yellow if support
            w.info ' workers_name : ' + r.workers.map(&:name).inspect.yellow if r.workers
            w.info ' equipments_name : ' + r.equipments.map(&:name).inspect.yellow if r.equipments

            plants = find_plants(support: support, variety: r.target_variety, at: r.intervention_started_at)
            w.info ' #{plants.count} plants : ' + plants.map(&:name).inspect.yellow if plants
            # if just one plant on support
            if plants.count <= 1
              intervention = send("record_#{r.procedure_name}", r, support, duration)
              # for the same intervention session
              r.intervention_started_at += duration.seconds if storage.shape
            elsif plants.count > 1
              # elsif two or more plants on support
              # create intervention for each plant
              duration_for_plant = (r.intervention_duration_in_hour.hours * (area / r.production_supports_area.to_d).to_d).round(2)
              for plant in plants
                coeff_by_plant_area = (plant.shape_area.to_d(:square_meter) / plants.map(&:shape_area).compact.sum.to_d).round(2)
                duration_for_plant = duration * coeff_by_plant_area
                intervention = send("record_#{r.procedure_name}", r, support, duration_for_plant, plant)
                r.intervention_started_at += duration_for_plant.seconds
              end
            end

          elsif storage.is_a?(BuildingDivision) || storage.is_a?(Equipment)
            duration = (r.intervention_duration_in_hour.hours / r.supports.count)
            intervention = send("record_#{r.procedure_name}", r, support, duration)
            # for the same intervention session
            r.intervention_started_at += duration.seconds
          else
            fail "Cannot handle this type of support storage: #{storage.inspect}"
          end
        end
      # case 2 no support but production find
      elsif production
        Ekylibre::FirstRun::Booker.production = production
        intervention = send("record_#{r.procedure_name}", r, production, r.intervention_duration_in_hour)
      else
        w.warn "Cannot add intervention #{r.intervention_number} without support neither production"
      end
      if intervention
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
        fail ActiveExchanger::NotWellFormedFileError, "Unknown unit #{unit.inspect} for variant #{item_variant.name.inspect}."
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
          fail "No way to divide by zero : variant indicator value is #{variant_indicator.inspect}"
        end
      elsif measure.dimension == :mass
        variant_indicator = variant.send(:net_mass)
        if variant_indicator.value.to_f != 0.0
          population_value = (measure.to_f(variant_indicator.unit.to_sym) / variant_indicator.value.to_f)
        else
          fail "No way to divide by zero : variant indicator value is #{variant_indicator.inspect}"
        end
      elsif measure.dimension == :distance
        variant_indicator = variant.send(:net_length)
        if variant_indicator.value.to_f != 0.0
          population_value = (measure.to_f(variant_indicator.unit.to_sym) / variant_indicator.value.to_f)
        else
          fail "No way to divide by zero : variant indicator value is #{variant_indicator.inspect}"
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
      intervention_started_at: ((row[2].blank? || row[3].blank?) ? nil : Time.strptime(Date.parse(row[2].to_s).strftime('%d/%m/%Y') + ' ' + row[3].to_s, '%d/%m/%Y %H:%M')),
      intervention_duration_in_hour: (row[4].blank? ? nil : row[4].tr(',', '.').to_d),
      procedure_name: (row[5].blank? ? nil : row[5].to_s.downcase.to_sym), # to transcode
      procedure_description: row[6].to_s,
      support_codes: (row[7].blank? ? nil : row[7].to_s.strip.delete(' ').upcase.split(',')),
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
      indicators: row[24].blank? ? {} : row[24].to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).collect { |i| i.split(/[[:space:]]*(\:|\=)[[:space:]]*/) }.inject({}) do |h, i|
        h[i.first.strip.downcase.to_sym] = i.third
        h
      end
    )
    # Get campaign
    unless r.campaign = Campaign.find_by_name(r.campaign_code)
      r.campaign = Campaign.create!(name: r.campaign_code, harvest_year: r.campaign_code)
    end
    # Get supports
    r.supports = parse_record_list(r.support_codes.delete_if { |s| %w(EXPLOITATION).include?(s) }, Product, :work_number)
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
      unless target_variant = ProductNatureVariant.find_by(number: r.target_variant)
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
                    ProductNatureVariant.find_by_number(a.product_code)
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
      fail "Cannot find #{klass.name.tableize} with #{column}: #{unfound.to_sentence}"
    end
    records
  end

  # find the best plant for the current support and cultivable zone by variety or variant
  def find_best_plant(options = {})
    plant = nil
    if options[:support] && options[:support].storage && options[:support].storage.shape
      # try to find the current plant on cultivable zone if exist
      cultivable_zone_shape = Charta::Geometry.new(options[:support].storage.shape)
      if cultivable_zone_shape && product_around = cultivable_zone_shape.actors_matching(nature: Plant)
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
    if options[:support] && options[:support].storage && options[:support].storage.shape
      # try to find the current plants on cultivable zone if exists
      cultivable_zone_shape = Charta::Geometry.new(options[:support].storage.shape)
      if cultivable_zone_shape && product_around = cultivable_zone_shape.actors_matching(nature: Plant)
        plants = Plant.where(id: product_around.map(&:id)).availables
      end
    end
    if options[:variety] && options[:at]
      members = options[:support].storage.contains(options[:variety], options[:at])
      plants = Plant.where(id: members.map(&:product_id)).availables if members
    elsif options[:variant] && options[:at]
      members = options[:support].storage.localized_variants(options[:variant], at: options[:at])
      plants = Plant.where(id: members.map(&:product_id)).availables if members
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
  #### SPRAYING / CUTTING       ####
  ##################################

  def record_spraying_on_land_parcel(r, support, duration, _plant = nil)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.first.product

    working_measure = find_plant_working_area(support: support, variety: r.target_variety, at: r.intervention_started_at, variant: r.target_variant)
    working_measure ||= cultivable_zone.shape_area

    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'plant_medicine', actor: r.first.product)
      i.add_cast(reference_name: 'plant_medicine_to_spray', population: first_product_input_population)
      i.add_cast(reference_name: 'sprayer',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(sprayer)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  def record_double_spraying_on_land_parcel(r, support, duration, _plant = nil)
    w.debug r.first.product.inspect.red
    w.debug r.second.product.inspect.red

    cultivable_zone = support.storage

    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.first.product && r.second.product
    working_measure = support.net_surface_area
    working_measure ||= cultivable_zone.shape_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)
    second_product_input_population = actor_population_conversion(r.second, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'first_plant_medicine', actor: r.first.product)
      i.add_cast(reference_name: 'first_plant_medicine_to_spray', population: first_product_input_population)
      i.add_cast(reference_name: 'second_plant_medicine', actor: r.second.product)
      i.add_cast(reference_name: 'second_plant_medicine_to_spray', population: second_product_input_population)
      i.add_cast(reference_name: 'sprayer',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(sprayer)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  def record_spraying_on_cultivation(r, support, duration, plant = nil)
    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end

    return nil unless plant && r.first.product

    unless working_measure = plant.net_surface_area
      working_measure = find_plant_working_area(support: support, variety: r.target_variety, at: r.intervention_started_at, variant: r.target_variant)
    end
    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'plant_medicine', actor: r.first.product)
      i.add_cast(reference_name: 'plant_medicine_to_spray', population: first_product_input_population)
      i.add_cast(reference_name: 'sprayer',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(sprayer)')))
      i.add_cast(reference_name: 'cultivation', actor: plant)
    end
    intervention
  end

  def record_double_spraying_on_cultivation(r, support, duration, plant = nil)
    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end

    return nil unless plant && r.first.product && r.second.product

    unless working_measure = plant.net_surface_area
      working_measure = find_plant_working_area(support: support, variety: r.target_variety, at: r.intervention_started_at, variant: r.target_variant)
    end

    w.info " Working measure : #{working_measure.inspect.green}"
    first_product_input_population = actor_population_conversion(r.first, working_measure)
    second_product_input_population = actor_population_conversion(r.second, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'first_plant_medicine', actor: r.first.product)
      i.add_cast(reference_name: 'first_plant_medicine_to_spray', population: first_product_input_population)
      i.add_cast(reference_name: 'second_plant_medicine', actor: r.second.product)
      i.add_cast(reference_name: 'second_plant_medicine_to_spray', population: second_product_input_population)
      i.add_cast(reference_name: 'sprayer',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(sprayer)')))
      i.add_cast(reference_name: 'cultivation', actor: plant)
    end
    intervention
  end

  def record_triple_spraying_on_cultivation(r, support, duration, plant = nil)
    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end

    return nil unless plant && r.first.product && r.second.product && r.third.product

    unless working_measure = plant.net_surface_area
      working_measure = find_plant_working_area(support: support, variety: r.target_variety, at: r.intervention_started_at, variant: r.target_variant)
    end
    first_product_input_population = actor_population_conversion(r.first, working_measure)
    second_product_input_population = actor_population_conversion(r.second, working_measure)
    third_product_input_population = actor_population_conversion(r.third, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'first_plant_medicine', actor: r.first.product)
      i.add_cast(reference_name: 'first_plant_medicine_to_spray', population: first_product_input_population)
      i.add_cast(reference_name: 'second_plant_medicine', actor: r.second.product)
      i.add_cast(reference_name: 'second_plant_medicine_to_spray', population: second_product_input_population)
      i.add_cast(reference_name: 'third_plant_medicine', actor: r.third.product)
      i.add_cast(reference_name: 'third_plant_medicine_to_spray', population: third_product_input_population)
      i.add_cast(reference_name: 'sprayer',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(sprayer)')))
      i.add_cast(reference_name: 'cultivation', actor: plant)
    end
    intervention
  end

  def record_cutting(r, support, duration, plant = nil)
    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end

    return nil unless plant

    unless working_measure = plant.net_surface_area
      working_measure = find_plant_working_area(support: support, variety: r.target_variety, at: r.intervention_started_at, variant: r.target_variant)
    end

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'cutter', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'cut') : i.find(Equipment, can: 'cut')))
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(sprayer)')))
      i.add_cast(reference_name: 'cultivation', actor: plant)
    end
    intervention
  end

  #######################
  ####  IMPLANTING  ####
  #######################

  def record_sowing(r, support, duration, _plant = nil)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.target_variant && r.first.product

    working_measure = cultivable_zone.shape_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)

    cultivation_population = (working_measure.to_s.to_f / 10_000.0) if working_measure
    # get density from first_product
    # (density in g per hectare / PMG) * 1000 * cultivable_area in hectare
    pmg = r.first.variant.thousand_grains_mass.to_d
    plants_count = (first_product_input_population * 1000 * 1000) / pmg if pmg && pmg != 0

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description, parameters: { readings: { 'base-sowing-0-1-readcount' => plants_count.to_i } }) do |i|
      i.add_cast(reference_name: 'seeds',        actor: r.first.product)
      i.add_cast(reference_name: 'seeds_to_sow', population: first_product_input_population)
      i.add_cast(reference_name: 'sower',        actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'sow') : i.find(Equipment, can: 'sow')))
      i.add_cast(reference_name: 'driver',       actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',      actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(sower)') : i.find(Equipment, can: 'tow(sower)')))
      i.add_cast(reference_name: 'land_parcel',  actor: cultivable_zone)
      i.add_cast(reference_name: 'cultivation',  variant: r.target_variant, population: cultivation_population, shape: cultivable_zone.shape)
    end
    intervention
  end

  def record_sowing_with_insecticide_and_molluscicide(r, support, duration, _plant = nil)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.target_variant && r.first.product && r.second.product && r.third.product

    working_measure = cultivable_zone.shape_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)
    second_product_input_population = actor_population_conversion(r.second, working_measure)
    third_product_input_population = actor_population_conversion(r.third, working_measure)

    cultivation_population = (working_measure.to_s.to_f / 10_000.0) if working_measure
    # get density from first_product
    # (density in g per hectare / PMG) * 1000 * cultivable_area in hectare
    pmg = r.first.variant.thousand_grains_mass.to_d
    plants_count = (first_product_input_population * 1000 * 1000) / pmg if pmg && pmg != 0

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description, parameters: { readings: { 'base-sowing_with_insecticide_and_molluscicide-0-1-readcount' => plants_count.to_i } }) do |i|
      i.add_cast(reference_name: 'seeds',        actor: r.first.product)
      i.add_cast(reference_name: 'seeds_to_sow', population: first_product_input_population)
      i.add_cast(reference_name: 'insecticide', actor: r.second.product)
      i.add_cast(reference_name: 'insecticide_to_input', population: second_product_input_population)
      i.add_cast(reference_name: 'molluscicide', actor: r.third.product)
      i.add_cast(reference_name: 'molluscicide_to_input', population: third_product_input_population)
      i.add_cast(reference_name: 'sower',        actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'sow') : i.find(Equipment, can: 'sow')))
      i.add_cast(reference_name: 'driver',       actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',      actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(sower)') : i.find(Equipment, can: 'tow(sower)')))
      i.add_cast(reference_name: 'land_parcel',  actor: cultivable_zone)
      i.add_cast(reference_name: 'cultivation',  variant: r.target_variant, population: cultivation_population, shape: cultivable_zone.shape)
    end
    intervention
  end

  def record_implanting(r, support, duration, _plant = nil)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.target_variant && r.first.product

    working_measure = cultivable_zone.shape_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)

    cultivation_population = (working_measure.to_s.to_f * 10_000.0) if working_measure

    # reading indicators on 1-2/3/4
    if r.indicators
      for indicator, value in r.indicators
        if indicator.to_sym == :rows_interval
          check_indicator_presence(r.target_variant, indicator.to_sym, :variable)
          rows_interval = value
        elsif indicator.to_sym == :plants_interval
          check_indicator_presence(r.target_variant, indicator.to_sym, :variable)
          plants_interval = value
        end
      end
    end

    plants_count = cultivation_population.to_i

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description, parameters: { readings: { 'base-implanting-0-1-readrowint' => rows_interval, 'base-implanting-0-1-readint' => plants_interval, 'base-implanting-0-1-readcount' => plants_count } }) do |i|
      i.add_cast(reference_name: 'plants',        actor: r.first.product)
      i.add_cast(reference_name: 'plants_to_fix', population: first_product_input_population)
      i.add_cast(reference_name: 'implanter_tool', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'implant') : i.find(Equipment, can: 'implant')))
      i.add_cast(reference_name: 'driver', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'implanter_man',       actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',      actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(equipment)') : i.find(Equipment, can: 'tow(equipment)')))
      i.add_cast(reference_name: 'land_parcel',  actor: cultivable_zone)
      i.add_cast(reference_name: 'cultivation',  variant: r.target_variant, population: cultivation_population, shape: cultivable_zone.shape)
    end
    intervention
  end

  def record_plastic_mulching(r, support, duration, _plant = nil)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.first.product

    working_measure = support.net_surface_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'plastic', actor: r.first.product)
      i.add_cast(reference_name: 'plastic_to_mulch', population: first_product_input_population)
      i.add_cast(reference_name: 'implanter', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'seat(canvas_cover)') : i.find(Equipment, can: 'seat(canvas_cover)')))
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(implanter)') : i.find(Equipment, can: 'catch(implanter)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  def record_implant_helping(r, support, duration, plant = nil)
    plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'implanter_man', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'cultivation', actor: (plant.present? ? plant : cultivable_zone))
    end
    intervention
  end

  #######################
  ####  FERTILIZING  ####
  #######################

  def record_organic_fertilizing(r, support, duration, _plant = nil)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.first.product

    working_measure = support.net_surface_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'manure', actor: r.first.product)
      i.add_cast(reference_name: 'manure_to_spread', population: first_product_input_population)
      i.add_cast(reference_name: 'spreader',    actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spread(preparation)') : i.find(Equipment, can: 'spread(preparation)')))
      i.add_cast(reference_name: 'driver',      actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',     actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(spreader)') : i.find(Equipment, can: 'tow(spreader)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  def record_mineral_fertilizing(r, support, duration, _plant = nil)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.first.product

    working_measure = support.net_surface_area

    w.debug working_measure.inspect.green
    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'fertilizer', actor: r.first.product)
      i.add_cast(reference_name: 'fertilizer_to_spread', population: first_product_input_population)
      i.add_cast(reference_name: 'spreader',    actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spread(preparation)') : i.find(Equipment, can: 'spread(preparation)')))
      i.add_cast(reference_name: 'driver',      actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',     actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(spreader)') : i.find(Equipment, can: 'tow(spreader)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  #######################
  ####  SOIL W       ####
  #######################

  def record_plowing(r, support, duration, _plant = nil)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, parameters: { readings: { 'base-plowing-0-1-readstate' => 'plowed' } }, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'plow', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'plow') : i.find(Equipment, can: 'plow')))
      i.add_cast(reference_name: 'driver',      actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',     actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(equipment)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  def record_raking(r, support, duration, _plant = nil)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, parameters: { readings: { 'base-raking-0-1-readstate' => 'plowed' } }, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'harrow', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'plow_superficially') : i.find(Equipment, can: 'plow_superficially')))
      i.add_cast(reference_name: 'driver',      actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',     actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(equipment)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  def record_hoeing(r, support, duration, _plant = nil)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, parameters: { readings: { 'base-hoeing-0-1-readstate' => 'plowed' } }, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'cultivator', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'hoe') : i.find(Equipment, can: 'hoe')))
      i.add_cast(reference_name: 'driver',      actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',     actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(equipment)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  def record_land_parcel_grinding(r, support, duration, _plant = nil)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'grinder', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'grind(cultivable_zone)') : i.find(Equipment, can: 'grind(cultivable_zone)')))
      i.add_cast(reference_name: 'driver',      actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',     actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(equipment)') : i.find(Equipment, can: 'tow(equipment)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  #######################
  ####  WATERING     ####
  #######################

  def record_watering(r, support, duration, plant = nil)
    cultivable_zone = support.storage

    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end

    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && plant && r.first.product

    unless working_measure = plant.net_surface_area
      working_measure = find_plant_working_area(support: support, variety: r.target_variety, at: r.intervention_started_at, variant: r.target_variant)
    end
    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'water',      actor: r.first.product)
      i.add_cast(reference_name: 'water_to_spread', population: first_product_input_population)
      i.add_cast(reference_name: 'spreader',    actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spread(water)') : i.find(Equipment, can: 'spread(water)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
      i.add_cast(reference_name: 'cultivation', actor: plant)
    end
    intervention
  end

  #################################
  ####  HARVESTING AND OTHER   ####
  #################################

  def record_grains_harvest(r, support, duration, plant = nil)
    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end

    return nil unless plant && r.first.variant && r.second.variant

    unless working_measure = plant.net_surface_area
      working_measure = find_plant_working_area(support: support, variety: r.target_variety, at: r.intervention_started_at, variant: r.target_variant)
    end

    first_product_input_population = actor_population_conversion(r.first, working_measure)
    second_product_input_population = actor_population_conversion(r.second, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'cropper',        actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'harvest(poaceae)') : i.find(Equipment, can: 'harvest(poaceae)')))
      i.add_cast(reference_name: 'cropper_driver', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'cultivation',    actor: plant)
      i.add_cast(reference_name: 'grains',         population: first_product_input_population, variant: r.first.variant)
      i.add_cast(reference_name: 'straws',         population: second_product_input_population, variant: r.second.variant)
    end
    intervention
  end

  def record_hazelnuts_harvest(r, support, duration, plant = nil)
    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end

    return nil unless plant && r.first.variant

    unless working_measure = plant.net_surface_area
      working_measure = find_plant_working_area(support: support, variety: r.target_variety, at: r.intervention_started_at, variant: r.target_variant)
    end

    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'nuts_harvester', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'harvest(hazelnut)') : i.find(Equipment, can: 'harvest(hazelnut)')))
      i.add_cast(reference_name: 'driver', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'cultivation', actor: plant)
      i.add_cast(reference_name: 'hazelnuts', population: first_product_input_population, variant: r.first.variant)
    end
    intervention
  end

  def record_plums_harvest(r, support, duration, plant = nil)
    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end

    return nil unless plant && r.first.variant

    unless working_measure = plant.net_surface_area
      working_measure = find_plant_working_area(support: support, variety: r.target_variety, at: r.intervention_started_at, variant: r.target_variant)
    end

    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'fruit_harvester', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'harvest(plum)') : i.find(Equipment, can: 'harvest(plum)')))
      i.add_cast(reference_name: 'tractor', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(equipment)') : i.find(Equipment, can: 'tow(equipment)')))
      i.add_cast(reference_name: 'driver', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'cultivation', actor: plant)
      i.add_cast(reference_name: 'fruits', population: first_product_input_population, variant: r.first.variant)
    end
    intervention
  end

  def record_plants_harvest(r, support, duration, plant = nil)
    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end

    return nil unless plant && r.first.variant

    unless working_measure = plant.net_surface_area
      working_measure = find_plant_working_area(support: support, variety: r.target_variety, at: r.intervention_started_at, variant: r.target_variant)
    end

    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'cropper',        actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'harvest(poaceae)') : i.find(Equipment, can: 'harvest(poaceae)')))
      i.add_cast(reference_name: 'cropper_driver', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'cultivation',    actor: plant)
      i.add_cast(reference_name: 'plants',         population: first_product_input_population, variant: r.first.variant)
    end
    intervention
  end

  def record_direct_silage(r, support, duration, plant = nil)
    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end

    return nil unless plant && r.first.variant

    unless working_measure = plant.net_surface_area
      working_measure = find_plant_working_area(support: support, variety: r.target_variety, at: r.intervention_started_at, variant: r.target_variant)
    end

    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'forager', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'harvest(plant)') : i.find(Equipment, can: 'harvest(plant)')))
      i.add_cast(reference_name: 'forager_driver', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'cultivation',    actor: plant)
      i.add_cast(reference_name: 'silage',         population: first_product_input_population, variant: r.first.variant)
    end
    intervention
  end

  def record_plantation_unfixing(r, support, duration, plant = nil)
    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end

    return nil unless plant

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(equipment)') : i.find(Equipment, can: 'tow(equipment)')))
      i.add_cast(reference_name: 'compressor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'blow') : i.find(Equipment, can: 'blow')))
      i.add_cast(reference_name: 'cultivation', actor: plant)
    end
    intervention
  end

  def record_harvest_helping(r, support, duration, plant = nil)
    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'harvester_man', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'cultivation', actor: (plant.present? ? plant : cultivable_zone))
    end
    intervention
  end

  def record_detasseling(r, support, duration, plant = nil)
    unless plant
      plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    end

    return nil unless plant

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'doer', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'cultivation', actor: plant)
    end
    intervention
  end

  #################################
  #### Technical & Maintenance ####
  #################################

  def record_fuel_up(r, support, duration, _plant = nil)
    equipment = support.storage

    return nil unless equipment && equipment.is_a?(Equipment) && r.first

    working_measure = nil

    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'mechanic', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'fuel', actor: r.first.product)
      i.add_cast(reference_name: 'fuel_to_input', population: first_product_input_population)
      i.add_cast(reference_name: 'equipment', actor: equipment)
    end
    intervention
  end

  def record_technical_task(r, support, duration, _plant = nil)
    zone = support.storage
    cultivable_zone = support.storage
    return nil unless (zone && (zone.is_a?(BuildingDivision) || zone.is_a?(Equipment))) || (cultivable_zone && cultivable_zone.is_a?(CultivableZone))

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'worker', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'target', actor: (cultivable_zone.present? ? cultivable_zone : zone))
    end
    intervention
  end

  def record_maintenance_task(r, support, duration, _plant = nil)
    if support.is_a?(ProductionSupport)
      zone = support.storage
      return nil unless zone && (zone.is_a?(BuildingDivision) || zone.is_a?(Equipment))
      intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
        i.add_cast(reference_name: 'worker', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
        i.add_cast(reference_name: 'maintained', actor: zone)
      end
    elsif support.is_a?(Production)
      return nil unless r.equipments.present? && r.workers.present?
      intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), description: r.procedure_description) do |i|
        i.add_cast(reference_name: 'worker', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
        i.add_cast(reference_name: 'maintained', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes) : zone))
      end
    end
    intervention
  end

  # Record administrative task
  def record_administrative_task(r, _production, duration, _plant = nil)
    return nil unless r.workers.present?
    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'worker', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
    end
    intervention
  end
end
