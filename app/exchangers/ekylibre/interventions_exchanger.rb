# coding: utf-8
class Ekylibre::InterventionsExchanger < ActiveExchanger::Base

  def import
    rows = CSV.read(file, headers: true, col_sep: ";").delete_if{|r| r[0].blank?}.sort{|a,b| [a[2].split(/\D/).reverse.join,a[0]] <=> [b[2].split(/\D/).reverse.join,b[0]]}

    w.count = rows.size

    # FIXME Translations in english please
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
      #CSV.foreach(path, headers: true, col_sep: ";") do |row|

      r = OpenStruct.new(  intervention_number: row[0].to_i,
                           campaign_code: row[1].to_s,
                           intervention_started_at: ((row[2].blank? || row[3].blank?) ? nil : Time.strptime(Date.parse(row[2].to_s).strftime('%d/%m/%Y') + " " + row[3].to_s, "%d/%m/%Y %H:%M")),
                           intervention_duration_in_hour: (row[4].blank? ? nil : row[4].gsub(",",".").to_d),
                           procedure_name: (row[5].blank? ? nil : row[5].to_s.downcase.to_sym), # to transcode
                           procedure_description: row[6].to_s,
                           support_codes: (row[7].blank? ? nil : row[7].to_s.strip.delete(' ').upcase.split(',')),
                           target_variant: (row[8].blank? ? nil : row[8].to_s.downcase.to_sym),
                           target_variety: (row[9].blank? ? nil : row[9].to_s.downcase.to_sym),
                           worker_codes: (row[10].blank? ? nil : row[10].to_s.strip.delete(' ').upcase.split(',')),
                           equipment_codes: (row[11].blank? ? nil : row[11].to_s.strip.delete(' ').upcase.split(',')),
                           ### FIRST PRODUCT
                           first_product_code: (row[12].blank? ? nil : row[12].to_s.upcase),
                           first_product_input_population: (row[13].blank? ? nil : row[13].gsub(",",".").to_d),
                           first_product_input_unit_name: (row[14].blank? ? nil : row[14].to_s.downcase),
                           first_product_input_unit_target_dose: (row[15].blank? ? nil : row[15].to_s.downcase),
                           ### SECOND PRODUCT
                           second_product_code: (row[16].blank? ? nil : row[16].to_s.upcase),
                           second_product_input_population: (row[17].blank? ? nil : row[17].gsub(",",".").to_d),
                           second_product_input_unit_name: (row[18].blank? ? nil : row[18].to_s.downcase),
                           second_product_input_unit_target_dose: (row[19].blank? ? nil : row[19].to_s.downcase),
                           ### THIRD PRODUCT
                           third_product_code: (row[20].blank? ? nil : row[20].to_s.upcase),
                           third_product_input_population: (row[21].blank? ? nil : row[21].gsub(",",".").to_d),
                           third_product_input_unit_name: (row[22].blank? ? nil : row[22].to_s.downcase),
                           third_product_input_unit_target_dose: (row[23].blank? ? nil : row[23].to_s.downcase)
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
      supports = Product.where(work_number: r.support_codes)
      if supports
        ps_ids = []
        # FIXME add a way to be more accurate
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
        production = Production.where(activity: activity, campaign: campaign).first if activity and campaign
      else
        activity = Activity.where(nature: :auxiliary, with_supports: false, with_cultivation: false).first
        production = Production.where(activity: activity, campaign: campaign).first if activity and campaign
      end

      # Get existing equipments and workers

      if r.equipment_codes
        equipments = Equipment.where(work_number: r.equipment_codes)
      end

      if r.worker_codes
        workers = Worker.where(work_number: r.worker_codes)
      end

      # Get products
      first_product = Product.find_by_work_number(r.first_product_code) if r.first_product_code
      second_product = Product.find_by_work_number(r.second_product_code) if r.second_product_code
      third_product = Product.find_by_work_number(r.third_product_code) if r.third_product_code


      if production_supports

        for support in production_supports

          if cultivable_zone = support.storage and cultivable_zone.is_a?(CultivableZone)

            plant = nil
            # find variant link to production
            plant_variant = support.production.variant if support
            # try to find the current plant on cultivable zone if exist
            cultivable_zone_shape = Charta::Geometry.new(cultivable_zone.shape) if cultivable_zone.shape
            if cultivable_zone_shape and product_around = cultivable_zone_shape.actors_matching(nature: Plant).first
              plant = product_around
            end

            duration = (duration_in_seconds * (cultivable_zone.shape_area.to_d / production_supports_area.to_d).to_d).round(2) if cultivable_zone.shape


            w.info "----------- #{r.intervention_number} / #{support.name} -----------".blue
            w.info " procedure : " + r.procedure_name.inspect.green
            w.info " started_at : " + intervention_started_at.inspect.yellow if intervention_started_at
            w.info " global duration : " + duration_in_seconds.inspect.yellow if duration_in_seconds
            w.info " duration : " + duration.to_f.inspect.yellow if duration
            w.info " first product : " + first_product.name.inspect.red if first_product
            w.info " first product quantity : " + r.first_product_input_population.to_s + " " + r.first_product_input_unit_name.to_s.inspect.red if r.first_product_input_population
            w.info " second product : " + second_product.name.inspect.red if second_product
            w.info " third product : " + third_product.name.inspect.red if third_product
            w.info " cultivable_zone : " + cultivable_zone.name.inspect.yellow + " - "  + cultivable_zone.work_number.inspect.yellow if cultivable_zone
            w.info " plant : " + plant.name.inspect.yellow if plant
            w.info " support : " + support.name.inspect.yellow if support
            w.info " workers_name : " + workers.pluck(:name).inspect.yellow if workers
            w.info " equipments_name : " + equipments.pluck(:name).inspect.yellow if equipments




            def population_conversion(product, population, unit, unit_target_dose, working_area = Measure.new(0.0, :square_meter))
              value = population
              unit = unit.to_sym
              nomen_unit = Nomen::Units[unit]
              if value > 0.0 and nomen_unit
                measure = Measure.new(value, unit)
                if measure
                  if unit == :liter || unit == :cubic_meter || unit == :hectoliter
                    variant_indicator = product.variant.send(:net_volume)
                  # convert measure to variant unit and divide by variant_indicator
                  # ex : for a wheat_seed_25kg
                  # 182.25 kilogram (converting in kilogram) / 25.00 kilogram
                  elsif unit == :kilogram || unit == :ton || unit == :quintal
                    variant_indicator = product.variant.send(:net_mass)
                  elsif unit == :meter
                    variant_indicator = product.variant.send(:net_length)
                  else
                    w.warn "Bad unit: #{unit} for intervention ##{r.intervention_number}"
                  end
                  population_value = ((measure.to_f(variant_indicator.unit.to_sym)) / variant_indicator.value.to_f)
                end
                if working_area.to_d(:square_meter) > 0.0
                  global_intrant_value = population_value.to_d * working_area.to_d(unit_target_dose.to_sym)
                  return global_intrant_value
                else
                  return population_value
                end
              end
            end


            coeff = ((cultivable_zone.shape_area / 10000.0) / 6.0).to_d if cultivable_zone.shape

            if r.procedure_name and support and (coeff.to_f > 0.0)

              intervention = nil

              Ekylibre::FirstRun::Booker.production = support.production

              ##################
              #### SPRAYING ####
              ##################

              if r.procedure_name == :double_spraying_on_cultivation and plant and first_product and second_product

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
                  i.add_cast(reference_name: 'sprayer',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "spray") : i.find(Equipment, can: "spray")))
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "catch(sprayer)") : i.find(Equipment, can: "catch(sprayer)")))
                  i.add_cast(reference_name: 'cultivation', actor: plant)
                end

              elsif r.procedure_name == :double_spraying_on_land_parcel and cultivable_zone and first_product and second_product

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
                  i.add_cast(reference_name: 'sprayer',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "spray") : i.find(Equipment, can: "spray")))
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "catch(sprayer)") : i.find(Equipment, can: "catch(sprayer)")))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end



              elsif r.procedure_name == :spraying_on_cultivation and plant and first_product

                working_measure = plant.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                # Spraying on cultivation
                intervention = Ekylibre::FirstRun::Booker.force(:spraying_on_cultivation, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'plant_medicine', actor: first_product)
                  i.add_cast(reference_name: 'plant_medicine_to_spray', population: first_product_input_population)
                  i.add_cast(reference_name: 'sprayer',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "spray") : i.find(Equipment, can: "spray")))
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "catch(sprayer)") : i.find(Equipment, can: "catch(sprayer)")))
                  i.add_cast(reference_name: 'cultivation', actor: plant)
                end

              elsif r.procedure_name == :spraying_on_land_parcel and cultivable_zone and first_product

                working_measure = cultivable_zone.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                # Spraying on cultivation
                intervention = Ekylibre::FirstRun::Booker.force(:spraying_on_land_parcel, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'plant_medicine', actor: first_product)
                  i.add_cast(reference_name: 'plant_medicine_to_spray', population: first_product_input_population)
                  i.add_cast(reference_name: 'sprayer',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "spray") : i.find(Equipment, can: "spray")))
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "catch(sprayer)") : i.find(Equipment, can: "catch(sprayer)")))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end


              ##################
              ####  W SOIL  ####
              ##################

              elsif r.procedure_name == :raking and cultivable_zone

                intervention = Ekylibre::FirstRun::Booker.force(:raking, intervention_started_at, (duration / 3600) , support: support, parameters: {readings: {"base-raking-0-500-1" => 'plowed'}}, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'harrow',      actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "plow_superficially") : i.find(Equipment, can: "plow_superficially")))
                  i.add_cast(reference_name: 'driver',      actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',     actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "catch(equipment)") : i.find(Equipment, can: "catch(equipment)")))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              elsif r.procedure_name == :plowing and cultivable_zone

                intervention = Ekylibre::FirstRun::Booker.force(:plowing, intervention_started_at, (duration / 3600) , support: support, parameters: {readings: {"base-plowing-0-500-1" => 'plowed'}}, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'plow',      actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "plow") : i.find(Equipment, can: "plow")))
                  i.add_cast(reference_name: 'driver',      actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',     actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "catch(equipment)") : i.find(Equipment, can: "catch(equipment)")))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              elsif r.procedure_name == :hoeing and cultivable_zone

                intervention = Ekylibre::FirstRun::Booker.force(:hoeing, intervention_started_at, (duration / 3600) , support: support, parameters: {readings: {"base-hoeing-0-500-1" => 'plowed'}}, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'cultivator',      actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "hoe") : i.find(Equipment, can: "hoe")))
                  i.add_cast(reference_name: 'driver',      actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',     actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "catch(equipment)") : i.find(Equipment, can: "catch(equipment)")))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              elsif r.procedure_name == :land_parcel_grinding and cultivable_zone

                intervention = Ekylibre::FirstRun::Booker.force(:land_parcel_grinding, intervention_started_at, (duration / 3600) , support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'grinder',      actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "grind(cultivable_zone)") : i.find(Equipment, can: "grind(cultivable_zone)")))
                  i.add_cast(reference_name: 'driver',      actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',     actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "tow(equipment)") : i.find(Equipment, can: "tow(equipment)")))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end


              #######################
              ####  FERTILIZING  ####
              #######################

              elsif r.procedure_name == :organic_fertilizing and cultivable_zone and first_product

                working_measure = cultivable_zone.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                # Organic fertilizing
                intervention = Ekylibre::FirstRun::Booker.force(:organic_fertilizing, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'manure',      actor: first_product)
                  i.add_cast(reference_name: 'manure_to_spread', population: first_product_input_population)
                  i.add_cast(reference_name: 'spreader',    actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "spread(preparation)") : i.find(Equipment, can: "spread(preparation)")))
                  i.add_cast(reference_name: 'driver',      actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',     actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "tow(spreader)") : i.find(Equipment, can: "tow(spreader)")))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end


              elsif r.procedure_name == :mineral_fertilizing and cultivable_zone and first_product

                working_measure = cultivable_zone.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                # Mineral fertilizing
                intervention = Ekylibre::FirstRun::Booker.force(:mineral_fertilizing, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'fertilizer',      actor: first_product)
                  i.add_cast(reference_name: 'fertilizer_to_spread', population: first_product_input_population)
                  i.add_cast(reference_name: 'spreader',    actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "spread(preparation)") : i.find(Equipment, can: "spread(preparation)")))
                  i.add_cast(reference_name: 'driver',      actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',     actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "tow(spreader)") : i.find(Equipment, can: "tow(spreader)")))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end


              #######################
              ####  INPLANTING   ####
              #######################

              elsif r.procedure_name == :plastic_mulching and cultivable_zone and first_product

                working_measure = cultivable_zone.shape_area
                w.info working_measure.inspect.green
                first_product_input_population = population_conversion(first_product, r.first_product_input_population, r.first_product_input_unit_name, r.first_product_input_unit_target_dose, working_measure)
                w.info first_product_input_population.inspect.green

                # Plastic mulching
                intervention = Ekylibre::FirstRun::Booker.force(:plastic_mulching, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'plastic', actor: first_product)
                  i.add_cast(reference_name: 'plastic_to_mulch', population: first_product_input_population)
                  i.add_cast(reference_name: 'implanter',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "seat(canvas_cover)") : i.find(Equipment, can: "seat(canvas_cover)")))
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "catch(implanter)") : i.find(Equipment, can: "catch(implanter)")))
                  i.add_cast(reference_name: 'land_parcel', actor: plant)
                end


              elsif r.procedure_name == :implant_helping and plant

                # Implant Helping with plant
                intervention = Ekylibre::FirstRun::Booker.force(:implant_helping, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'implanter_man',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'cultivation', actor: plant)
                end

              elsif r.procedure_name == :implant_helping and cultivable_zone

                # Implant Helping with cultivable_zone
                intervention = Ekylibre::FirstRun::Booker.force(:implant_helping, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'implanter_man',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'cultivation', actor: cultivable_zone)
                end


              elsif r.procedure_name == :plantation_unfixing and plant

                # Implant Helping with plant
                intervention = Ekylibre::FirstRun::Booker.force(:plantation_unfixing, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "catch(implanter)") : i.find(Equipment, can: "catch(implanter)")))
                  i.add_cast(reference_name: 'compressor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "blow") : i.find(Equipment, can: "blow")))
                  i.add_cast(reference_name: 'cultivation', actor: plant)
                end

               elsif r.procedure_name == :plantation_unfixing and cultivable_zone

                # Implant Helping with plant
                intervention = Ekylibre::FirstRun::Booker.force(:plantation_unfixing, intervention_started_at, (duration / 3600), support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'driver',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'tractor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "catch(implanter)") : i.find(Equipment, can: "catch(implanter)")))
                  i.add_cast(reference_name: 'compressor',  actor: (equipments.any? ? i.find(Equipment, work_number: r.equipment_codes, can: "blow") : i.find(Equipment, can: "blow")))
                  i.add_cast(reference_name: 'cultivation', actor: cultivable_zone)
                end

              end
            end
            # for the same intervention session
            intervention_started_at += duration.seconds if cultivable_zone.shape

          elsif zone = support.storage and ( zone.is_a?(BuildingDivision) || zone.is_a?(Equipment) || zone.is_a?(CultivableZone) )

            if r.procedure_name and support

              intervention = nil

              Ekylibre::FirstRun::Booker.production = support.production

              #####################
              #### MAINTENANCE ####
              #####################

              if r.procedure_name == :maintenance_task and zone

                # Maintenance_task
                intervention = Ekylibre::FirstRun::Booker.force(:maintenance_task, intervention_started_at, duration_in_seconds, support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'worker',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'maintained', actor: zone)
                end

              elsif r.procedure_name == :technical_task and zone

                #####################
                #### Technical ####
                #####################

                # Technical task
                intervention = Ekylibre::FirstRun::Booker.force(:technical_task, intervention_started_at, duration_in_seconds, support: support, description: r.procedure_description) do |i|
                  i.add_cast(reference_name: 'worker',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
                  i.add_cast(reference_name: 'target', actor: zone)
                end

              end
            end




          end

          if intervention
            intervention.description += " - " + information_import_context + " - N° : " + r.intervention_number.to_s + " - " + support.name
            intervention.save!
            w.info "Intervention n°#{intervention.id} - #{intervention.name} has been created".green
          else
            w.info "Intervention is in a black hole".red
          end


        end



      elsif production

        if r.procedure_name

          intervention = nil

          Ekylibre::FirstRun::Booker.production = production

          ########################
          #### ADMINISTRATIVE ####
          ########################

          if r.procedure_name == :administrative_task

            # Administrative_task
            intervention = Ekylibre::FirstRun::Booker.force(:administrative_task, intervention_started_at, duration_in_seconds, description: r.procedure_description) do |i|
              i.add_cast(reference_name: 'worker',   actor: (workers.any? ? i.find(Worker, work_number: r.worker_codes) : i.find(Worker)))
            end

          end
        end

        if intervention
          intervention.description += " - " + information_import_context + " - N° : " + r.intervention_number.to_s + " - " + support.name
          intervention.save!
          w.info "Intervention n°#{intervention.id} - #{intervention.name} has been created".green
        else
          w.info "Intervention is in a black hole".red
        end


      end

      w.check_point
    end

  end

end
