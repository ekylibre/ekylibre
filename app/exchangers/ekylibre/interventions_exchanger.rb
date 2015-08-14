# coding: utf-8
class Ekylibre::InterventionsExchanger < ActiveExchanger::Base
  def check_file!
    rows = CSV.read(file, headers: true, col_sep: ';').delete_if { |r| r[0].blank? }.sort { |a, b| [a[2].split(/\D/).reverse.join, a[0]] <=> [b[2].split(/\D/).reverse.join, b[0]] }
    valid = true
    w.count = rows.size
    rows.each_with_index do |row, index|
      line_number = index
      r = OpenStruct.new(intervention_number: row[0].to_i,
                         campaign_code: row[1].to_s,
                         intervention_started_at: ((row[2].blank? || row[3].blank?) ? nil : Time.strptime(Date.parse(row[2].to_s).strftime('%d/%m/%Y') + ' ' + row[3].to_s, '%d/%m/%Y %H:%M')),
                         intervention_duration_in_hour: (row[4].blank? ? nil : row[4].tr(',', '.').to_d),
                         procedure_name: (row[5].blank? ? nil : row[5].to_s.downcase.to_sym), # to transcode
                         procedure_description: row[6].to_s,
                         support_codes: (row[7].blank? ? nil : row[7].to_s.strip.delete(' ').upcase.split(',')),
                         target_variant: (row[8].blank? ? nil : row[8].to_s.downcase.to_sym),
                         target_variety: (row[9].blank? ? nil : row[9].to_s.downcase.to_sym),
                         worker_codes: (row[10].blank? ? nil : row[10].to_s.strip.delete(' ').upcase.split(',')),
                         equipment_codes: (row[11].blank? ? nil : row[11].to_s.strip.delete(' ').upcase.split(',')),
                         ### FIRST PRODUCT
                         first_product_code: (row[12].blank? ? nil : row[12].to_s.upcase),
                         first_product_input_population: (row[13].blank? ? nil : row[13].tr(',', '.').to_d),
                         first_product_input_unit_name: (row[14].blank? ? nil : row[14].to_s.downcase),
                         first_product_input_unit_target_dose: (row[15].blank? ? nil : row[15].to_s.downcase),
                         ### SECOND PRODUCT
                         second_product_code: (row[16].blank? ? nil : row[16].to_s.upcase),
                         second_product_input_population: (row[17].blank? ? nil : row[17].tr(',', '.').to_d),
                         second_product_input_unit_name: (row[18].blank? ? nil : row[18].to_s.downcase),
                         second_product_input_unit_target_dose: (row[19].blank? ? nil : row[19].to_s.downcase),
                         ### THIRD PRODUCT
                         third_product_code: (row[20].blank? ? nil : row[20].to_s.upcase),
                         third_product_input_population: (row[21].blank? ? nil : row[21].tr(',', '.').to_d),
                         third_product_input_unit_name: (row[22].blank? ? nil : row[22].to_s.downcase),
                         third_product_input_unit_target_dose: (row[23].blank? ? nil : row[23].to_s.downcase)
                        )

      # info, warn, error
      # valid = false if error
      #
      # PROCEDURE EXIST IN NOMENCLATURE
      #
      procedure_long_name = "base-" + procedure_name.to_s + "-0"
      procedure_nomen = Procedo[procedure_long_name]
      unless procedure_nomen
        w.error "#{line_number}: No procedure given"
        valid = false
      end
      #
      # PROCEDURE HAVE A DURATION
      #
      intervention_started_at = r.intervention_started_at
      if duration_in_seconds = r.intervention_duration_in_hour.hours
        intervention_stopped_at = intervention_started_at + duration_in_seconds
      else
        w.warn "#{line_number}: Need a duration"
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
      for product in [r.first_product_code, r.second_product_code, r.third_product_code]
        if product
          if p = Product.find_by_work_number(product)
            w.info "#{line_number}: #{product} exist in DB as a product ( #{p.name} )"
          elsif v = ProductNatureVariant.find_by_number(product)
            w.info "#{line_number}: #{product} exist in DB as a variant ( #{p.name} )"
          elsif item = Nomen::ProductNatureVariants.find(r.target_variant)
            w.info "#{line_number}: #{product} exist in NOMENCLATURE as a variant ( #{item.name} )"
          else
            w.error "#{line_number}: #{product} does not exist in DB as a product or as a variant in DB or NOMENCLATURE"
            valid = false
          end
        end
      end
      #
      # PROCEDURE GIVE UNIT BUT NOT EXIST IN NOMENCLATURE
      #
      for unit in [r.first_product_input_unit_name, r.second_product_input_unit_name, r.third_product_input_unit_name]
        if Nomen::Units[unit]
          w.info "#{line_number}: #{unit} exist in NOMENCLATURE as a unit"
        elsif u = Nomen::Units.find_by(symbol: unit)
          w.info "#{line_number}: #{unit} exist in NOMENCLATURE as a symbol of #{u.name}"
        else
          w.error "#{line_number}: Unknown unit #{unit}"
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

    rows.each do |row| #
      # CSV.foreach(path, headers: true, col_sep: ";") do |row|

      r = OpenStruct.new(intervention_number: row[0].to_i,
                         campaign_code: row[1].to_s,
                         intervention_started_at: ((row[2].blank? || row[3].blank?) ? nil : Time.strptime(Date.parse(row[2].to_s).strftime('%d/%m/%Y') + ' ' + row[3].to_s, '%d/%m/%Y %H:%M')),
                         intervention_duration_in_hour: (row[4].blank? ? nil : row[4].tr(',', '.').to_d),
                         procedure_name: (row[5].blank? ? nil : row[5].to_s.downcase.to_sym), # to transcode
                         procedure_description: row[6].to_s,
                         support_codes: (row[7].blank? ? nil : row[7].to_s.strip.delete(' ').upcase.split(',')),
                         target_variant: (row[8].blank? ? nil : row[8].to_s.downcase.to_sym),
                         target_variety: (row[9].blank? ? nil : row[9].to_s.downcase.to_sym),
                         worker_codes: (row[10].blank? ? nil : row[10].to_s.strip.delete(' ').upcase.split(',')),
                         equipment_codes: (row[11].blank? ? nil : row[11].to_s.strip.delete(' ').upcase.split(',')),
                         ### FIRST PRODUCT
                         first_product_code: (row[12].blank? ? nil : row[12].to_s.upcase),
                         first_product_input_population: (row[13].blank? ? nil : row[13].tr(',', '.').to_d),
                         first_product_input_unit_name: (row[14].blank? ? nil : row[14].to_s.downcase),
                         first_product_input_unit_target_dose: (row[15].blank? ? nil : row[15].to_s.downcase),
                         ### SECOND PRODUCT
                         second_product_code: (row[16].blank? ? nil : row[16].to_s.upcase),
                         second_product_input_population: (row[17].blank? ? nil : row[17].tr(',', '.').to_d),
                         second_product_input_unit_name: (row[18].blank? ? nil : row[18].to_s.downcase),
                         second_product_input_unit_target_dose: (row[19].blank? ? nil : row[19].to_s.downcase),
                         ### THIRD PRODUCT
                         third_product_code: (row[20].blank? ? nil : row[20].to_s.upcase),
                         third_product_input_population: (row[21].blank? ? nil : row[21].tr(',', '.').to_d),
                         third_product_input_unit_name: (row[22].blank? ? nil : row[22].to_s.downcase),
                         third_product_input_unit_target_dose: (row[23].blank? ? nil : row[23].to_s.downcase),
                         indicators: row[24].blank? ? {} : row[24].to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.inject({}) do |h, i|
                           h[i.first.strip.downcase.to_sym] = i.second
                           h
                         end
                        )

      intervention_started_at = r.intervention_started_at
      if duration_in_seconds = r.intervention_duration_in_hour.hours
        intervention_stopped_at = intervention_started_at + duration_in_seconds
      else
        w.warn "Need a duration for intervention ##{r.intervention_number}"
      end

      intervention_year = intervention_started_at.year
      intervention_month = intervention_started_at.month
      intervention_day = intervention_started_at.day

      # Get campaign
      unless campaign = Campaign.find_by_name(r.campaign_code)
        campaign = Campaign.create!(name: r.campaign_code, harvest_year: r.campaign_code)
      end

      # Get supports and existing production_supports or activity by activity family input
      production_supports = nil
      production = nil
      supports = Product.where(work_number: r.support_codes)
      if supports
        ps_ids = []
        # FIXME: add a way to be more accurate
        # find a uniq support for each product because a same cultivable zone could be a support of many productions
        for product in supports
          ps = ProductionSupport.of_campaign(campaign).where(storage: product).first
          ps_ids << ps.id if ps
        end
        production_supports = ProductionSupport.of_campaign(campaign).find(ps_ids)
        # Get global supports area (square_meter)
        production_supports_area = production_supports.map(&:storage_shape_area).compact.sum
      elsif r.support_codes
        activity = Activity.where(family: r.support_codes.first.to_sym).first
        production = Production.where(activity: activity, campaign: campaign).first if activity && campaign
      else
        activity = Activity.where(nature: :auxiliary, with_supports: false, with_cultivation: false).first
        production = Production.where(activity: activity, campaign: campaign).first if activity && campaign
      end

      # Get existing equipments  
      equipments = Equipment.where(work_number: r.equipment_codes) if r.equipment_codes
      workers = Worker.where(work_number: r.worker_codes) if r.worker_codes

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

      # Get products or variants
      if r.first_product_code
        unless first_product = Product.find_by_work_number(r.first_product_code)
          first_variant = ProductNatureVariant.find_by_number(r.first_product_code)
        end
      end

      if r.second_product_code
        unless second_product = Product.find_by_work_number(r.second_product_code)
          second_variant = ProductNatureVariant.find_by_number(r.second_product_code)
        end
      end

      if r.third_product_code
        unless third_product = Product.find_by_work_number(r.third_product_code)
          third_variant = ProductNatureVariant.find_by_number(r.third_product_code)
        end
      end

      if production_supports

        # puts r.intervention_number.inspect.red
        # puts r.procedure_name.inspect.green

        production_supports.each do |support|
          if cultivable_zone = support.storage and cultivable_zone.is_a?(CultivableZone)

            plant = nil
            # find variant link to production
            plant_variant = support.production.variant if support
            # try to find the current plant on cultivable zone if exist
            cultivable_zone_shape = Charta::Geometry.new(cultivable_zone.shape) if cultivable_zone.shape
            if cultivable_zone_shape && product_around = cultivable_zone_shape.actors_matching(nature: Plant).first
              plant = product_around
            end
            if r.target_variety
              members = cultivable_zone.contains(r.target_variety, r.intervention_started_at)
              plant = members.first.product if members
            end

            duration = (duration_in_seconds * (cultivable_zone.shape_area.to_d / production_supports_area.to_d).to_d).round(2) if cultivable_zone.shape

            w.info "----------- #{r.intervention_number} / #{support.name} -----------".blue
            w.info ' procedure : ' + r.procedure_name.inspect.green
            w.info ' started_at : ' + intervention_started_at.inspect.yellow if intervention_started_at
            w.info ' global duration : ' + duration_in_seconds.inspect.yellow if duration_in_seconds
            w.info ' duration : ' + duration.to_f.inspect.yellow if duration
            w.info ' first product : ' + first_product.name.inspect.red if first_product
            w.info ' first product quantity : ' + r.first_product_input_population.to_s + ' ' + r.first_product_input_unit_name.to_s.inspect.red if r.first_product_input_population
            w.info ' second product : ' + second_product.name.inspect.red if second_product
            w.info ' third product : ' + third_product.name.inspect.red if third_product
            w.info ' cultivable_zone : ' + cultivable_zone.name.inspect.yellow + ' - ' + cultivable_zone.work_number.inspect.yellow if cultivable_zone
            w.info ' plant : ' + plant.name.inspect.yellow if plant
            w.info ' support : ' + support.name.inspect.yellow if support
            w.info ' workers_name : ' + workers.pluck(:name).inspect.yellow if workers
            w.info ' equipments_name : ' + equipments.pluck(:name).inspect.yellow if equipments

            def population_conversion(product, population, unit, unit_target_dose, working_area = Measure.new(0.0, :square_meter))
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
              if value > 0.0 && nomen_unit
                measure = Measure.new(value, unit)
                if measure
                  if unit == :liter || unit == :cubic_meter || unit == :hectoliter
                    variant_indicator = product_variant.send(:net_volume)
                  # convert measure to variant unit and divide by variant_indicator
                  # ex : for a wheat_seed_25kg
                  # 182.25 kilogram (converting in kilogram) / 25.00 kilogram
                  elsif unit == :kilogram || unit == :ton || unit == :quintal
                    variant_indicator = product_variant.send(:net_mass)
                  elsif unit == :meter
                    variant_indicator = product_variant.send(:net_length)
                  else
                    w.warn "Bad unit: #{unit} for intervention ##{r.intervention_number}"
                  end
                  population_value = ((measure.to_f(variant_indicator.unit.to_sym)) / variant_indicator.value.to_f)
                end
              # case population
              elsif value > 0.0 && !nomen_unit
                population_value = value
              end
              if working_area.to_d(:square_meter) > 0.0
                global_intrant_value = population_value.to_d * working_area.to_d(unit_target_dose.to_sym)
                return global_intrant_value
              else
                return population_value
              end
            end

            area = cultivable_zone.shape
            coeff = ((cultivable_zone.shape_area / 10_000.0) / 6.0).to_d if area

            if r.procedure_name && support && (coeff.to_f > 0.0)

              intervention = nil

              Ekylibre::FirstRun::Booker.production = support.production

              ##################
              #### SPRAYING ####
              ##################

              if r.procedure_name == :double_spraying_on_cultivation && plant && first_product && second_product

                working_measure = plant.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green
                second_product_input_population = population_conversion(second_product, r.second_product_input_population, r.second_product_input_unit_name, r.second_product_input_unit_target_dose, working_measure)
                w.info second_product_input_population.inspect.green

                # Double spraying on cultivation
                intervention = Ekylibre::FirstRun::Booker.force(:double_spraying_on_cultivation, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'first_plant_medicine', actor: first_product)
                  i.add_cast(reference_name: 'first_plant_medicine_to_spray', population: first_product_input_population)
                  i.add_cast(reference_name: 'second_plant_medicine', actor: second_product)
                  i.add_cast(reference_name: 'second_plant_medicine_to_spray', population: second_product_input_population)
                  i.add_cast(reference_name: 'sprayer',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(sprayer)') : i.find(Equipment, can: 'catch(sprayer)')))
                  i.add_cast(reference_name: 'cultivation', actor: plant)
                end

              elsif r.procedure_name == :double_spraying_on_land_parcel && cultivable_zone && first_product && second_product

                working_measure = cultivable_zone.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green
                second_product_input_population = population_conversion(second_product, r.second_product_input_population, r.second_product_input_unit_name, r.second_product_input_unit_target_dose, working_measure)
                w.info second_product_input_population.inspect.green

                # Double spraying on cultivation
                intervention = Ekylibre::FirstRun::Booker.force(:double_spraying_on_land_parcel, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'first_plant_medicine', actor: first_product)
                  i.add_cast(reference_name: 'first_plant_medicine_to_spray', population: first_product_input_population)
                  i.add_cast(reference_name: 'second_plant_medicine', actor: second_product)
                  i.add_cast(reference_name: 'second_plant_medicine_to_spray', population: second_product_input_population)
                  i.add_cast(reference_name: 'sprayer',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(sprayer)') : i.find(Equipment, can: 'catch(sprayer)')))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              elsif r.procedure_name == :spraying_on_cultivation && plant && first_product

                working_measure = plant.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                # Spraying on cultivation
                intervention = Ekylibre::FirstRun::Booker.force(:spraying_on_cultivation, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'plant_medicine', actor: first_product)
                  i.add_cast(reference_name: 'plant_medicine_to_spray', population: first_product_input_population)
                  i.add_cast(reference_name: 'sprayer',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(sprayer)') : i.find(Equipment, can: 'catch(sprayer)')))
                  i.add_cast(reference_name: 'cultivation', actor: plant)
                end

              elsif r.procedure_name == :spraying_on_land_parcel && cultivable_zone && first_product

                working_measure = cultivable_zone.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                # Spraying on cultivation
                intervention = Ekylibre::FirstRun::Booker.force(:spraying_on_land_parcel, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'plant_medicine', actor: first_product)
                  i.add_cast(reference_name: 'plant_medicine_to_spray', population: first_product_input_population)
                  i.add_cast(reference_name: 'sprayer',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spray') : i.find(Equipment, can: 'spray')))
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(sprayer)') : i.find(Equipment, can: 'catch(sprayer)')))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              ##################
              ####  W SOIL  ####
              ##################

              elsif r.procedure_name == :raking && cultivable_zone

                intervention = Ekylibre::FirstRun::Booker.force(:raking, intervention_started_at, (duration / 3600), support: support, parameters: { readings: { 'base-raking-0-500-1' => 'plowed' } }, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'harrow',      actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'plow_superficially') : i.find(Equipment, can: 'plow_superficially')))
                  i.add_cast(reference_name: 'driver',      actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',     actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(equipment)')))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              elsif r.procedure_name == :plowing && cultivable_zone

                intervention = Ekylibre::FirstRun::Booker.force(:plowing, intervention_started_at, (duration / 3600), support: support, parameters: { readings: { 'base-plowing-0-500-1' => 'plowed' } }, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'plow', actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'plow') : i.find(Equipment, can: 'plow')))
                  i.add_cast(reference_name: 'driver',      actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',     actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(equipment)')))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              elsif r.procedure_name == :hoeing && cultivable_zone

                intervention = Ekylibre::FirstRun::Booker.force(:hoeing, intervention_started_at, (duration / 3600), support: support, parameters: { readings: { 'base-hoeing-0-500-1' => 'plowed' } }, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'cultivator', actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'hoe') : i.find(Equipment, can: 'hoe')))
                  i.add_cast(reference_name: 'driver',      actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',     actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(equipment)')))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              elsif r.procedure_name == :land_parcel_grinding && cultivable_zone

                intervention = Ekylibre::FirstRun::Booker.force(:land_parcel_grinding, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'grinder', actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'grind(cultivable_zone)') : i.find(Equipment, can: 'grind(cultivable_zone)')))
                  i.add_cast(reference_name: 'driver',      actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',     actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(equipment)') : i.find(Equipment, can: 'tow(equipment)')))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              #######################
              ####  FERTILIZING  ####
              #######################

              elsif r.procedure_name == :organic_fertilizing && cultivable_zone && first_product

                working_measure = cultivable_zone.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                # Organic fertilizing
                intervention = Ekylibre::FirstRun::Booker.force(:organic_fertilizing, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'manure',      actor: first_product)
                  i.add_cast(reference_name: 'manure_to_spread', population: first_product_input_population)
                  i.add_cast(reference_name: 'spreader',    actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spread(preparation)') : i.find(Equipment, can: 'spread(preparation)')))
                  i.add_cast(reference_name: 'driver',      actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',     actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(spreader)') : i.find(Equipment, can: 'tow(spreader)')))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              elsif r.procedure_name == :mineral_fertilizing && cultivable_zone && first_product

                working_measure = cultivable_zone.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                # Mineral fertilizing
                intervention = Ekylibre::FirstRun::Booker.force(:mineral_fertilizing, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'fertilizer',      actor: first_product)
                  i.add_cast(reference_name: 'fertilizer_to_spread', population: first_product_input_population)
                  i.add_cast(reference_name: 'spreader',    actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spread(preparation)') : i.find(Equipment, can: 'spread(preparation)')))
                  i.add_cast(reference_name: 'driver',      actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',     actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(spreader)') : i.find(Equipment, can: 'tow(spreader)')))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              ####################################
              ####  SOWING / IMPLANTING       ####
              ####################################

              elsif r.procedure_name == :sowing && cultivable_zone && target_variant && first_product

                working_measure = cultivable_zone.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                cultivation_population = (working_measure.to_s.to_f / 10_000.0) if working_measure
                # get density from first_product
                # (density in g per hectare / PMG) * 1000 * cultivable_area in hectare
                pmg = first_product.variant.thousand_grains_mass.to_d
                plants_count = (first_product_input_population * 1000 * 1000) / pmg if pmg && pmg != 0

                # Sowing
                intervention = Ekylibre::FirstRun::Booker.force(:sowing, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description, parameters: { readings: { 'base-sowing-0-750-2' => plants_count.to_i } }) do |i|
                  i.add_cast(reference_name: 'seeds',        actor: first_product)
                  i.add_cast(reference_name: 'seeds_to_sow', population: first_product_input_population)
                  i.add_cast(reference_name: 'sower',        actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'sow') : i.find(Equipment, can: 'sow')))
                  i.add_cast(reference_name: 'driver',       actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',      actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(sower)') : i.find(Equipment, can: 'tow(sower)')))
                  i.add_cast(reference_name: 'land_parcel',  actor: cultivable_zone)
                  i.add_cast(reference_name: 'cultivation',  variant: target_variant, population: cultivation_population, shape: cultivable_zone.shape)
                end

              elsif r.procedure_name == :implanting && cultivable_zone && target_variant && first_product

                working_measure = cultivable_zone.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

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

                # Implanting
                intervention = Ekylibre::FirstRun::Booker.force(:implanting, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description, parameters: { readings: { 'base-implanting-0-750-2' => rows_interval.to_d, 'base-implanting-0-750-3' => plants_interval.to_d, 'base-implanting-0-750-4' => plants_count.to_i } }) do |i|
                  i.add_cast(reference_name: 'plants',        actor: first_product)
                  i.add_cast(reference_name: 'plants_to_fix', population: first_product_input_population)
                  i.add_cast(reference_name: 'implanter_tool', actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'implant') : i.find(Equipment, can: 'implant')))
                  i.add_cast(reference_name: 'driver', actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'implanter_man',       actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',      actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(equipment)') : i.find(Equipment, can: 'tow(equipment)')))
                  i.add_cast(reference_name: 'land_parcel',  actor: cultivable_zone)
                  i.add_cast(reference_name: 'cultivation',  variant: target_variant, population: cultivation_population, shape: cultivable_zone.shape)
                end

              #######################
              ####  HARVESTING   ####
              #######################

              elsif r.procedure_name == :grains_harvest && plant && first_variant && second_variant

                working_measure = plant.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_variant, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green
                second_product_input_population = population_conversion(second_variant, r.second_product_input_population, r.second_product_input_unit_name, r.second_product_input_unit_target_dose, working_measure)
                w.info second_product_input_population.inspect.green

                puts plant.inspect.red
                puts equipments.inspect.yellow
                puts first_variant.inspect.yellow
                puts second_variant.inspect.yellow

                intervention = Ekylibre::FirstRun::Booker.force(:grains_harvest, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'cropper',        actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'harvest(poaceae)') : i.find(Equipment, can: 'harvest(poaceae)')))
                  i.add_cast(reference_name: 'cropper_driver', actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'cultivation',    actor: plant)
                  i.add_cast(reference_name: 'grains',         population: first_product_input_population, variant: first_variant)
                  i.add_cast(reference_name: 'straws',         population: second_product_input_population, variant: second_variant)
                end

              elsif r.procedure_name == :direct_silage && plant && first_product

                working_measure = plant.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                intervention = Ekylibre::FirstRun::Booker.force(:direct_silage, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'forager',        actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'harvest(plant)') : i.find(Equipment, can: 'harvest(plant)')))
                  i.add_cast(reference_name: 'forager_driver', actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'cultivation',    actor: plant)
                  i.add_cast(reference_name: 'silage',         population: first_product_input_population, variant: first_product.variant)
                end

              #######################
              ####  WATERING  ####
              #######################

              elsif r.procedure_name == :watering && cultivable_zone && plant && first_product

                working_measure = cultivable_zone.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                # Watering
                intervention = Ekylibre::FirstRun::Booker.force(:watering, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'water',      actor: first_product)
                  i.add_cast(reference_name: 'water_to_spread', population: first_product_input_population)
                  i.add_cast(reference_name: 'spreader',    actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'spread(water)') : i.find(Equipment, can: 'spread(water)')))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                  i.add_cast(reference_name: 'cultivation', actor: plant)
                end

              #######################
              ####  INPLANTING   ####
              #######################

              elsif r.procedure_name == :plastic_mulching && cultivable_zone && first_product

                working_measure = cultivable_zone.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                # Plastic mulching
                intervention = Ekylibre::FirstRun::Booker.force(:plastic_mulching, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'plastic', actor: first_product)
                  i.add_cast(reference_name: 'plastic_to_mulch', population: first_product_input_population)
                  i.add_cast(reference_name: 'implanter', actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'seat(canvas_cover)') : i.find(Equipment, can: 'seat(canvas_cover)')))
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'catch(implanter)') : i.find(Equipment, can: 'catch(implanter)')))
                  i.add_cast(reference_name: 'land_parcel', actor: plant)
                end

              elsif r.procedure_name == :implant_helping && plant

                # Implant Helping with plant
                intervention = Ekylibre::FirstRun::Booker.force(:implant_helping, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'implanter_man', actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'cultivation', actor: plant)
                end

              elsif r.procedure_name == :implant_helping && cultivable_zone

                # Implant Helping with cultivable_zone
                intervention = Ekylibre::FirstRun::Booker.force(:implant_helping, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'implanter_man', actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'cultivation', actor: cultivable_zone)
                end
              #
              elsif r.procedure_name == :plantation_unfixing && plant
                # Implant Helping with plant
                intervention = Ekylibre::FirstRun::Booker.force(:plantation_unfixing, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'tow(equipment)') : i.find(Equipment, can: 'tow(equipment)')))
                  i.add_cast(reference_name: 'compressor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: 'blow') : i.find(Equipment, can: 'blow')))
                  i.add_cast(reference_name: 'cultivation', actor: plant)
                end

              elsif r.procedure_name == :technical_task && cultivable_zone

                #####################
                #### Technical ####
                #####################

                # Technical task
                intervention = Ekylibre::FirstRun::Booker.force(:technical_task, intervention_started_at, duration_in_seconds, support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'worker', actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'target', actor: cultivable_zone)
                end

              end
            end
            # for the same intervention session
            intervention_started_at += duration.seconds if cultivable_zone.shape

          elsif zone = support.storage and (zone.is_a?(BuildingDivision) || zone.is_a?(Equipment))

            if r.procedure_name && support

              intervention = nil
              Ekylibre::FirstRun::Booker.production = support.production
              #####################
              #### MAINTENANCE ####
              #####################

              if r.procedure_name == :maintenance_task && zone

                # Maintenance_task
                intervention = Ekylibre::FirstRun::Booker.force(:maintenance_task, intervention_started_at, duration_in_seconds, support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'worker', actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'maintained', actor: zone)
                end

              elsif r.procedure_name == :technical_task && zone

                #####################
                #### Technical ####
                #####################
                # Technical task
                intervention = Ekylibre::FirstRun::Booker.force(:technical_task, intervention_started_at, duration_in_seconds, support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'worker', actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'target', actor: zone)
                end
              end
            end

          end
          if intervention
            intervention.description += ' - ' + information_import_context + ' - N° : ' + r.intervention_number.to_s + ' - ' + support.name
            intervention.save!
            w.info "Intervention n°#{intervention.id} - #{intervention.name} has been created".green
          else
            w.info 'Intervention is in a black hole'.red
          end
        end

      elsif production

        puts r.intervention_number.inspect.red
        puts r.procedure_name.inspect.yellow

        if r.procedure_name
          intervention = nil

          Ekylibre::FirstRun::Booker.production = production

          ########################
          #### ADMINISTRATIVE ####
          ########################

          # case no supports
          if r.procedure_name == :maintenance_task && workers.any? && equipments.any?
            # Maintenance_task
            intervention = Ekylibre::FirstRun::Booker.force(:maintenance_task, intervention_started_at, duration_in_seconds, description: r.procedure_description) do |i|
              i.add_cast(reference_name: 'worker', actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
              i.add_cast(reference_name: 'maintained', actor: i.find(Equipment, work_number: r.equipment_codes))
            end
          elsif r.procedure_name == :administrative_task && workers.any?
            # Administrative task
            intervention = Ekylibre::FirstRun::Booker.force(:administrative_task, intervention_started_at, duration_in_seconds, description: r.procedure_description) do |i|
              i.add_cast(reference_name: 'worker', actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
            end
          end
        end
        if intervention
          intervention.description += ' - ' + information_import_context + ' - N° : ' + r.intervention_number.to_s + ' - ' + support.name
          intervention.save!
          w.info "Intervention n°#{intervention.id} - #{intervention.name} has been created".green
        else
          w.info 'Intervention is in a black hole'.red
        end
      end
      w.check_point
    end
  end
end
