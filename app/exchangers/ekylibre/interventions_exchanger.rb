# coding: utf-8
class Ekylibre::InterventionsExchanger < ActiveExchanger::Base
  def check
    rows = CSV.read(file, headers: true, col_sep: ';').delete_if { |r| r[0].blank? }.sort { |a, b| [a[2].split(/\D/).reverse.join, a[0]] <=> [b[2].split(/\D/).reverse.join, b[0]] }
    valid = true
    w.count = rows.size
    rows.each_with_index do |row, index|
      line_number = index
      r = parse_row(row)

      # info, warn, error
      # valid = false if error
      #
      # PROCEDURE EXIST IN NOMENCLATURE
      #
      procedure_long_name = 'base-' + r.procedure_name.to_s + '-0'
      procedure_nomen = Procedo[procedure_long_name]
      unless procedure_nomen
        w.error "#{line_number}: No procedure given"
        valid = false
      end
      #
      # PROCEDURE HAVE A DURATION
      #
      unless r.intervention_duration_in_hour.hours
        w.error "#{line_number}: Need a duration"
        valid = false
      end
      #
      # PROCEDURE GIVE A CAMPAIGN WHO DOES NOT EXIST IN DB
      #
      unless campaign = Campaign.find_by_name(r.campaign_code)
        w.info "#{line_number}: #{r.campaign_code} will be created as a campaign"
      end
      #
      # PROCEDURE GIVE SUPPORTS CODES BUT NOT EXIST IN DB
      #
      if r.support_codes
        unless supports = Product.where(work_number: r.support_codes)
          w.warn "#{line_number}: #{r.support_codes} does not exist in DB"
          w.info "#{line_number}: a standard activity will be set"
        end
      end
      #
      # PROCEDURE GIVE VARIANT OR VARIETY CODES BUT NOT EXIST IN DB OR IN NOMENCLATURE
      #
      if r.target_variety && !r.target_variant
        unless Nomen::Varieties.find(r.target_variety)
          w.error "#{line_number}: #{r.target_variety} does not exist in NOMENCLATURE"
          valid = false
        end
      elsif r.target_variant
        if variant = ProductNatureVariant.find_by(number: r.target_variant)
          w.info "#{line_number}: #{r.target_variant} exist in DB ( #{variant.name} )"
        elsif item = Nomen::ProductNatureVariants.find(r.target_variant)
          w.info "#{line_number}: #{r.target_variant} exist in NOMENCLATURE ( #{item.name} )"
        else
          w.error "#{line_number}: #{r.target_variant} does not exist in NOMENCLATURE or DB"
          valid = false
        end
      end
      #
      # PROCEDURE GIVE EQUIPMENTS CODES BUT NOT EXIST IN DB
      #
      if r.equipment_codes
        unless equipments = Equipment.where(work_number: r.equipment_codes)
          w.warn "#{line_number}: #{r.equipment_codes} does not exist in DB"
        end
      end
      #
      # PROCEDURE GIVE WORKERS CODES BUT NOT EXIST IN DB
      #
      if r.worker_codes
        unless workers = Worker.where(work_number: r.worker_codes)
          w.warn "#{line_number}: #{r.worker_codes} does not exist in DB"
        end
      end
      #
      # PROCEDURE GIVE PRODUCTS OR VARIANTS BUT NOT EXIST IN DB
      #
      for o in [r.first, r.second, r.third]
        if o
          if o.product.is_a?(Product)
            w.info "#{line_number}: #{o} exist in DB as a product ( #{o.product.name} )"
          elsif o.variant.is_a?(ProductNatureVariant)
            w.info "#{line_number}: #{o} exist in DB as a variant ( #{o.variant.name} )"
          elsif item = Nomen::ProductNatureVariants.find(o.target_variant)
            w.info "#{line_number}: #{o} exist in NOMENCLATURE as a variant ( #{item.name} )"
          else
            w.error "#{line_number}: #{o} does not exist in DB as a product or as a variant in DB or NOMENCLATURE"
            valid = false
          end
        end
      end
      #
      # PROCEDURE GIVE UNIT BUT NOT EXIST IN NOMENCLATURE
      #
      for unit_name in [r.first.input_unit_name, r.second.input_unit_name, r.third.input_unit_name]
        if Nomen::Units[unit_name]
          w.info "#{line_number}: #{unit_name} exist in NOMENCLATURE as a unit"
        elsif u = Nomen::Units.find_by(symbol: unit_name)
          w.info "#{line_number}: #{unit_name} exist in NOMENCLATURE as a symbol of #{u.name}"
        else
          w.error "#{line_number}: Unknown unit #{unit_name}"
          valid = false
        end
      end
    end
    valid
  end

  def import
    rows = CSV.read(file, headers: true, col_sep: ';').delete_if { |r| r[0].blank? }.sort { |a, b| [a[2].split(/\D/).reverse.join, a[0]] <=> [b[2].split(/\D/).reverse.join, b[0]] }

    w.count = rows.size

    # FIXME: Translations in english please
    # 0 "ID intervention"
    # 1 "campagne"
    # 2 "date debut intervention"
    # 3 "heure debut intervention"
    # 4 "durée (heure)"
    # 5 "procedure reference_name CF NOMENCLATURE"
    # 6 "description"
    # 7 "codes des supports travaillés [array] CF WORK_NUMBER"
    # 8 "variant de la cible (target) CF NOMENCLATURE"
    # 9 "variété de la cible (target) CF NOMENCLATURE"
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

    information_import_context = "Import Ekylibre interventions on #{Time.now.l}"

    rows.each do |row, index| #
      # CSV.foreach(path, headers: true, col_sep: ";") do |row|

      r = parse_row(row)

      if r.intervention_duration_in_hour.hours
        r.intervention_stopped_at = r.intervention_started_at + r.intervention_duration_in_hour.hours
      else
        w.warn "Need a duration for intervention ##{r.intervention_number}"
      end

      intervention_year = r.intervention_started_at.year
      intervention_month = r.intervention_started_at.month
      intervention_day = r.intervention_started_at.day

      # Get campaign
      unless campaign = Campaign.find_by_name(r.campaign_code)
        campaign = Campaign.create!(name: r.campaign_code, harvest_year: r.campaign_code)
      end

      # Get supports and existing production_supports or activity by activity family input
      production_supports = nil
      production = nil
      supports = nil
      supports = Product.where(work_number: r.support_codes)
      if supports.any?
        ps_ids = []
        # FIXME: add a way to be more accurate
        # find a uniq support for each product because a same cultivable zone could be a support of many productions
        for product in supports
          ps = ProductionSupport.of_campaign(campaign).where(storage: product).first
          ps_ids << ps.id if ps
        end
        production_supports = ProductionSupport.of_campaign(campaign).find(ps_ids)
        # Get global supports area (square_meter)
        r.production_supports_area = production_supports.map(&:storage_shape_area).compact.sum
      elsif r.support_codes.present?
        puts r.support_codes.inspect.red
        activity = Activity.where(family: r.support_codes.flatten.first.downcase.to_sym).first
        puts activity.name.inspect.green if activity
        production = Production.where(activity: activity, campaign: campaign).first if activity && campaign
        puts production.name.inspect.green if production
      else
        activity = Activity.where(nature: :auxiliary, with_supports: false, with_cultivation: false).first
        production = Production.where(activity: activity, campaign: campaign).first if activity && campaign
      end

      # Get existing equipments
      r.equipments = nil
      r.equipments = Equipment.where(work_number: r.equipment_codes)
      r.workers = nil
      r.workers = Worker.where(work_number: r.worker_codes)

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

      # case 1 support and production find
      if production_supports

        # puts r.intervention_number.inspect.red
        # puts r.procedure_name.inspect.green

        production_supports.each do |support|
          if cultivable_zone = support.storage and cultivable_zone.is_a?(CultivableZone)

            duration = (r.intervention_duration_in_hour.hours * (cultivable_zone.shape_area.to_d / r.production_supports_area.to_d).to_d).round(2) if cultivable_zone.shape

            w.info "----------- #{r.intervention_number} / #{support.name} -----------".blue
            w.info ' procedure : ' + r.procedure_name.inspect.green
            w.info ' started_at : ' + r.intervention_started_at.inspect.yellow if r.intervention_started_at
            w.info ' first product : ' + r.first.product.name.inspect.red if r.first.product
            w.info ' first product quantity : ' + r.first.product.input_population.to_s + ' ' + r.first.product.input_unit_name.to_s.inspect.red if r.first.product_input_population
            w.info ' second product : ' + r.second.product.name.inspect.red if r.second.product
            w.info ' third product : ' + r.third.product.name.inspect.red if r.third.product
            w.info ' cultivable_zone : ' + cultivable_zone.name.inspect.yellow + ' - ' + cultivable_zone.work_number.inspect.yellow if cultivable_zone
            w.info ' support : ' + support.name.inspect.yellow if support
            w.info ' workers_name : ' + r.workers.pluck(:name).inspect.yellow if r.workers
            w.info ' equipments_name : ' + r.equipments.pluck(:name).inspect.yellow if r.equipments

            area = cultivable_zone.shape
            coeff = ((cultivable_zone.shape_area / 10_000.0) / 6.0).to_d if area

            intervention = nil

            Ekylibre::FirstRun::Booker.production = support.production

            #### SPRAYING ####
            if r.procedure_name == :double_spraying_on_cultivation || r.procedure_name == :spraying_on_cultivation || r.procedure_name == :spraying_on_land_parcel || r.procedure_name == :double_spraying_on_land_parcel

              intervention = send("record_#{r.procedure_name}", r, support, duration)

            ####  SOIL W  ####
            elsif (r.procedure_name == :raking || r.procedure_name == :plowing || r.procedure_name == :hoeing || r.procedure_name == :land_parcel_grinding )

            ####  SOIL W  ####
            elsif r.procedure_name == :raking || r.procedure_name == :plowing || r.procedure_name == :hoeing || r.procedure_name == :land_parcel_grinding

              intervention = send("record_#{r.procedure_name}", r, support, duration)

            ####  FERTILIZING  ####
            elsif r.procedure_name == :organic_fertilizing || r.procedure_name == :mineral_fertilizing

              intervention = send("record_#{r.procedure_name}", r, support, duration)

            ####  SOWING / IMPLANTING       ####
            elsif r.procedure_name == :sowing || r.procedure_name == :implanting

              intervention = send("record_#{r.procedure_name}", r, support, duration)

            ####  HARVESTING   ####
            elsif r.procedure_name == :grains_harvest && r.first.variant && r.second.variant

              intervention = send("record_#{r.procedure_name}", r, support, duration)

            elsif r.procedure_name == :direct_silage && r.first.variant

              intervention = send("record_#{r.procedure_name}", r, support, duration)

            elsif r.procedure_name == :plantation_unfixing

              intervention = send("record_#{r.procedure_name}", r, support, duration)

            ####  WATERING     ####
            elsif r.procedure_name == :watering && r.first.product

              intervention = send("record_#{r.procedure_name}", r, support, duration)

            ####  INPLANTING   ####
            elsif r.procedure_name == :plastic_mulching && r.first.product

              intervention = send("record_#{r.procedure_name}", r, support, duration)

            elsif r.procedure_name == :implant_helping

              intervention = send("record_#{r.procedure_name}", r, support, duration)

            ####  MAINTENANCE   ####
            elsif r.procedure_name == :technical_task

              intervention = send("record_#{r.procedure_name}", r, support, duration)

            end

            # for the same intervention session
            r.intervention_started_at += duration.seconds if cultivable_zone.shape

          elsif zone = support.storage and (zone.is_a?(BuildingDivision) || zone.is_a?(Equipment))

            intervention = nil

            Ekylibre::FirstRun::Booker.production = support.production

            duration = (r.intervention_duration_in_hour.hours / supports.count)

            #### MAINTENANCE ####
            if r.procedure_name == :maintenance_task || r.procedure_name == :technical_task || r.procedure_name == :fuel_up

              intervention = send("record_#{r.procedure_name}", r, support, duration)

            end
            # for the same intervention session
            r.intervention_started_at += duration.seconds

          end
          if intervention
            intervention.description += ' - ' + information_import_context + ' - N° : ' + r.intervention_number.to_s + ' - ' + support.name
            intervention.save!
            w.info "Intervention n°#{intervention.id} - #{intervention.name} has been created".green
          else
            w.info 'Intervention is in a black hole'.red
          end
        end
      # end of support loop

      # case 2 no support but production find
      elsif production

        if r.procedure_name
          intervention = nil

          Ekylibre::FirstRun::Booker.production = production

          if r.procedure_name == :maintenance_task || r.procedure_name == :administrative_task
            puts "IN CASE 2"
            intervention = send("record_#{r.procedure_name}", r, production, r.intervention_duration_in_hour)

          end

        end

        if intervention
          intervention.description += ' - ' + information_import_context + ' - N° : ' + r.intervention_number.to_s
          intervention.save!
          w.info "Intervention n°#{intervention.id} - #{intervention.name} has been created".green
        else
          w.info 'Intervention is in a black hole'.red
        end

      end
      w.check_point
    end
  end

  protected

  # convert measure to variant unit and divide by variant_indicator
  # ex : for a wheat_seed_25kg
  # 182.25 kilogram (converting in kilogram) / 25.00 kilogram
  def population_conversion(product, population, unit, unit_target_dose, working_area = 0.0.square_meter)
    if product.is_a?(Product)
      product_variant = product.variant
    elsif product.is_a?(ProductNatureVariant)
      product_variant = product
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
    if value >= 0.0 && nomen_unit
      measure = Measure.new(value, unit)
      if measure.dimension == :volume
        variant_indicator = product_variant.send(:net_volume)
      elsif measure.dimension == :mass
        variant_indicator = product_variant.send(:net_mass)
      elsif measure.dimension == :length
        variant_indicator = product_variant.send(:net_length)
      else
        w.warn "Bad unit: #{unit} for intervention"
      end
      population_value = ((measure.to_f(variant_indicator.unit.to_sym)) / variant_indicator.value.to_f)

    # case population
    elsif value >= 0.0 && !nomen_unit
      population_value = value
    end
    if working_area and working_area.to_d(:square_meter) > 0.0
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

  # parse a row of the current file
  def parse_row(row)
    return OpenStruct.new(intervention_number: row[0].to_i,
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
                          indicators: row[24].blank? ? {} : row[24].to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.inject({}) do |h, i|
                            h[i.first.strip.downcase.to_sym] = i.second
                            h
                          end
                         )
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
      if a.product = Product.find_by_work_number(a.product_code)
        a.variant = a.product.variant
      else
        a.variant = ProductNatureVariant.find_by_number(a.product_code)
      end
    end

    a
  end

  # find the best plant for the current support and cultivable zone
  def find_best_plant(options = {})
    plant = nil
    if options[:support] && options[:support].storage && options[:support].storage.shape
      # try to find the current plant on cultivable zone if exist
      cultivable_zone_shape = Charta::Geometry.new(options[:support].storage.shape)
      if cultivable_zone_shape && product_around = cultivable_zone_shape.actors_matching(nature: Plant).first
        plant = product_around
      end
    end
    if options[:variety] && options[:at]
      members = options[:support].storage.contains(options[:variety], options[:at])
      plant = members.first.product if members
    end
    plant
  end

  ########################
  #### SPRAYING       ####
  ########################

  def record_spraying_on_land_parcel(r, support, duration)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.first.product

    working_measure = cultivable_zone.shape_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'plant_medicine', actor: r.first.product)
      i.add_cast(reference_name: 'plant_medicine_to_spray', population: first_product_input_population)
      i.add_cast(reference_name: 'sprayer',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(sprayer)') : i.find(Equipment, can: 'catch(sprayer)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  def record_double_spraying_on_land_parcel(r, support, duration)
    
    puts r.first.product.inspect.red
    puts r.second.product.inspect.red
    
    cultivable_zone = support.storage
    
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.first.product && r.second.product

    working_measure = cultivable_zone.shape_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)
    second_product_input_population = actor_population_conversion(r.second, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'first_plant_medicine', actor: r.first.product)
      i.add_cast(reference_name: 'first_plant_medicine_to_spray', population: first_product_input_population)
      i.add_cast(reference_name: 'second_plant_medicine', actor: r.second.product)
      i.add_cast(reference_name: 'second_plant_medicine_to_spray', population: second_product_input_population)
      i.add_cast(reference_name: 'sprayer',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(sprayer)') : i.find(Equipment, can: 'catch(sprayer)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  def record_spraying_on_cultivation(r, support, duration)
    plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)

    return nil unless plant && r.first.product

    working_measure = plant.shape_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'plant_medicine', actor: r.first.product)
      i.add_cast(reference_name: 'plant_medicine_to_spray', population: first_product_input_population)
      i.add_cast(reference_name: 'sprayer',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(sprayer)') : i.find(Equipment, can: 'catch(sprayer)')))
      i.add_cast(reference_name: 'cultivation', actor: plant)
    end
    intervention
  end

  def record_double_spraying_on_cultivation(r, support, duration)
    plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)

    return nil unless plant && r.first.product && r.second.product

    working_measure = plant.shape_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)
    second_product_input_population = actor_population_conversion(r.second, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'first_plant_medicine', actor: r.first.product)
      i.add_cast(reference_name: 'first_plant_medicine_to_spray', population: first_product_input_population)
      i.add_cast(reference_name: 'second_plant_medicine', actor: r.second.product)
      i.add_cast(reference_name: 'second_plant_medicine_to_spray', population: second_product_input_population)
      i.add_cast(reference_name: 'sprayer',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(sprayer)') : i.find(Equipment, can: 'catch(sprayer)')))
      i.add_cast(reference_name: 'cultivation', actor: plant)
    end
    intervention
  end

  #######################
  ####  IMPLANTING  ####
  #######################

  def record_sowing(r, support, duration)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.target_variant && r.first.product

    working_measure = cultivable_zone.shape_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)

    cultivation_population = (working_measure.to_s.to_f / 10_000.0) if working_measure
    # get density from first_product
    # (density in g per hectare / PMG) * 1000 * cultivable_area in hectare
    pmg = r.first.variant.thousand_grains_mass.to_d
    plants_count = (first_product_input_population * 1000 * 1000) / pmg if pmg && pmg != 0

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description, parameters: { readings: { 'base-sowing-0-750-2' => plants_count.to_i } }) do |i|
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

  def record_implanting(r, support, duration)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.target_variant && r.first.product

    working_measure = cultivable_zone.shape_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)

    cultivation_population = (working_measure.to_s.to_f / 10_000.0) if working_measure

    rows_interval = 0
    plants_interval = 0
    # check indicators linked to matters
    if r.indicators
      for indicator, value in r.indicators
        if indicator.to_sym == :rows_interval
          rows_interval = value
        elsif indicator.to_sym == :plants_interval
          plants_interval = value
        end
      end
    end
    # reading indicators on 750-2/3/4
    plants_count = cultivation_population

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description, parameters: { readings: { 'base-implanting-0-750-2' => rows_interval.to_d, 'base-implanting-0-750-3' => plants_interval.to_d, 'base-implanting-0-750-4' => plants_count.to_i } }) do |i|
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

  def record_plastic_mulching(r, support, duration)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.first.product

    working_measure = cultivable_zone.shape_area
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

  def record_implant_helping(r, support, duration)

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

  def record_organic_fertilizing(r, support, duration)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.first.product
    working_measure = cultivable_zone.shape_area
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

  def record_mineral_fertilizing(r, support, duration)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && r.first.product

    working_measure = cultivable_zone.shape_area
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

  def record_plowing(r, support, duration)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, parameters: { readings: { 'base-plowing-0-500-1' => 'plowed' } }, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'plow', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'plow') : i.find(Equipment, can: 'plow')))
      i.add_cast(reference_name: 'driver',      actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',     actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(equipment)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  def record_raking(r, support, duration)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, parameters: { readings: { 'base-raking-0-500-1' => 'plowed' } }, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'harrow', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'plow_superficially') : i.find(Equipment, can: 'plow_superficially')))
      i.add_cast(reference_name: 'driver',      actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',     actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(equipment)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  def record_hoeing(r, support, duration)
    cultivable_zone = support.storage
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, parameters: { readings: { 'base-hoeing-0-500-1' => 'plowed' } }, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'cultivator', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'hoe') : i.find(Equipment, can: 'hoe')))
      i.add_cast(reference_name: 'driver',      actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',     actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(equipment)')))
      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
    end
    intervention
  end

  def record_land_parcel_grinding(r, support, duration)
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

  def record_watering(r, support, duration)
    cultivable_zone = support.storage
    plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    return nil unless cultivable_zone && cultivable_zone.is_a?(CultivableZone) && plant && r.first.product

    working_measure = cultivable_zone.shape_area
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

  #######################
  ####  HARVESTING   ####
  #######################

  def record_grains_harvest(r, support, duration)
    plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)

    return nil unless plant && r.first.variant && r.second.variant

    working_measure = plant.shape_area

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

  def record_direct_silage(r, support, duration)
    plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)

    return nil unless plant && r.first.variant

    working_measure = plant.shape_area
    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'forager', actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'harvest(plant)') : i.find(Equipment, can: 'harvest(plant)')))
      i.add_cast(reference_name: 'forager_driver', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'cultivation',    actor: plant)
      i.add_cast(reference_name: 'silage',         population: first_product_input_population, variant: r.first.variant)
    end
    intervention
  end

  def record_plantation_unfixing(r, support, duration)
    plant = find_best_plant(support: support, variety: r.target_variety, at: r.intervention_started_at)
    return nil unless plant

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'driver',   actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'tractor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(equipment)') : i.find(Equipment, can: 'tow(equipment)')))
      i.add_cast(reference_name: 'compressor',  actor: (r.equipments.present? ? i.find(Equipment, work_number: r.equipment_codes, can: 'blow') : i.find(Equipment, can: 'blow')))
      i.add_cast(reference_name: 'cultivation', actor: plant)
    end
    intervention
  end

  #################################
  #### Technical & Maintenance ####
  #################################

  def record_fuel_up(r, support, duration)

    equipment = support.storage

    return nil unless equipment and equipment.is_a?(Equipment) and r.first

    working_measure = nil

    first_product_input_population = actor_population_conversion(r.first, working_measure)

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'mechanic', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'fuel',      actor: r.first.product)
      i.add_cast(reference_name: 'fuel_to_input', population: first_product_input_population)
      i.add_cast(reference_name: 'equipment', actor: equipment)
    end
    return intervention
  end

  def record_technical_task(r, support, duration)


    zone = support.storage
    cultivable_zone = support.storage
    return nil unless (zone and (zone.is_a?(BuildingDivision) || zone.is_a?(Equipment))) || (cultivable_zone && cultivable_zone.is_a?(CultivableZone))

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'worker', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
      i.add_cast(reference_name: 'target', actor: (cultivable_zone.present? ? cultivable_zone : zone))
    end
    return intervention
  end

  def record_maintenance_task(r, support, duration)

    if support.is_a?(ProductionSupport)
      zone = support.storage
      return nil unless zone and (zone.is_a?(BuildingDivision) || zone.is_a?(Equipment))

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
    return intervention

  end

  def record_administrative_task(r, production, duration)

    return nil unless r.workers.present?

    intervention = Ekylibre::FirstRun::Booker.force(r.procedure_name.to_sym, r.intervention_started_at, (duration / 3600), description: r.procedure_description) do |i|
      i.add_cast(reference_name: 'worker', actor: (r.workers.present? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
    end
    return intervention

  end

end
