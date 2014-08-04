# -*- coding: utf-8 -*-
load_data :interventions do |loader|


  # load interventions from viniteca

  # get Viniteca product name and linked Ekylibre variant
  #
  variants_transcode = {}.with_indifferent_access

  path = loader.path("viniteca", "variants_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      variants_transcode[row[0]] = row[1].to_sym
    end
  end

  # get Viniteca issue nature name and linked Ekylibre incident nature
  #
  issue_natures_transcode = {}.with_indifferent_access

  path = loader.path("viniteca", "issue_natures_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      issue_natures_transcode[row[0]] = row[1].to_sym
    end
  end

  # get Viniteca procedure name and linked Ekylibre procedure
  #
  procedures_transcode = {}.with_indifferent_access

  path = loader.path("viniteca", "procedures_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      procedures_transcode[row[0]] = row[1].to_sym
    end
  end


  path = loader.path("viniteca", "interventions.csv")
  if path.exist?
    loader.count :viniteca_intervention_import do |w|

    information_import_context = "Import from viniteca on #{Time.now.l}"

    CSV.foreach(path, headers: true, col_sep: ";") do |row|

      r = OpenStruct.new(    cultivable_zone_name: row[1].gsub("-h","").downcase,
                             working_area: row[2].gsub(",",".").to_d,
                             cultivable_zone_area: row[3].gsub(",",".").to_d,
                             intervention_started_at: (row[4].blank? ? nil : DateTime.strptime(row[4].to_s, "%d/%m/%Y %H:%M")),

                             intervention_stopped_at: (row[5].blank? ? nil : DateTime.strptime(row[5].to_s, "%d/%m/%Y %H:%M")),
                             procedure_name: row[6].to_s.downcase, # to transcode
                             product_name: row[7].to_s.downcase, # to create
                             product_input_population: row[8].gsub(",",".").to_d,
                             product_input_population_per_hectare: row[9].gsub(",",".").to_d,
                             product_input_dose_per_hectare: (row[10].blank? ? nil : row[10].gsub(",",".").to_d), # for legal quantity ?
                             incident_name: (row[11].blank? ? nil : row[11].to_s.downcase), # to transcode
                             dar: (row[12].blank? ? nil : row[12].to_i), # indicator on product for delay_before_harvest in day
                             product_input_approved_dose_per_hectare: (row[13].blank? ? nil : row[13].gsub(",",".").to_d) # legal quantity in liter per hectare

                             )



      intervention_started_at = r.intervention_started_at + 9.hours
      intervention_year = intervention_started_at.year
      intervention_month = intervention_started_at.month
      intervention_day = intervention_started_at.day
      intervention_stopped_at = r.intervention_stopped_at + 11.hours

      campaign = Campaign.find_by_harvest_year(intervention_started_at.year)
      campaign ||= Campaign.create!(name: intervention_started_at.year, harvest_year: intervention_started_at.year)
      plant = Plant.find_by_identification_number(r.cultivable_zone_name)

      puts "----------- #{w.count} -----------".blue
      # puts r.product_name.inspect.green
      puts " procedure : " + procedures_transcode[r.procedure_name].inspect.green
      puts " variant : " + variants_transcode[r.product_name].inspect.red
      puts " plant : " + plant.inspect.red


      if plant and campaign
        cultivable_zone = plant.container
        if support = ProductionSupport.where(storage: cultivable_zone).of_campaign(campaign).first
          Ekylibre::FirstRun::Booker.production = support.production
          coeff = (r.working_area / 10000.0) / 6.0


          #
          # create product
          #



          if r.product_name and ( procedures_transcode[r.procedure_name] == :mineral_fertilizing || procedures_transcode[r.procedure_name] == :organic_fertilizing )

            variant = ProductNatureVariant.import_from_nomenclature(variants_transcode[r.product_name])

            intrant = variant.generate(r.product_name, r.intervention_started_at, plant.container)

              unless intrant.frozen_indicators_list.include?(:population)
                intrant.read!(:population, r.product_input_population, :at => r.intervention_started_at)
              end

          elsif r.product_name and procedures_transcode[r.procedure_name] == :chemical_weed

            variant = ProductNatureVariant.import_from_nomenclature(:herbicide)

            intrant = variant.generate(r.product_name, r.intervention_started_at, plant.container)
              unless intrant.frozen_indicators_list.include?(:population)
                intrant.read!(:population, r.product_input_population, :at => r.intervention_started_at)
              end
              intrant.read!(:wait_before_harvest_period, r.dar.in_day, :at => r.intervention_started_at) if r.dar
              intrant.read!(:approved_input_dose, r.product_input_approved_dose_per_hectare.in_kilogram_per_hectare, :at => r.intervention_started_at) if r.product_input_approved_dose_per_hectare

           elsif r.product_name and procedures_transcode[r.procedure_name] == :spraying_on_cultivation

            variant = ProductNatureVariant.import_from_nomenclature(:fungicide)

            intrant = variant.generate(r.product_name, r.intervention_started_at, plant.container)

              unless intrant.frozen_indicators_list.include?(:population)
                intrant.read!(:population, r.product_input_population, :at => r.intervention_started_at)
              end
              intrant.read!(:wait_before_harvest_period, r.dar.in_day, :at => r.intervention_started_at) if r.dar
              intrant.read!(:approved_input_dose, r.product_input_approved_dose_per_hectare.in_kilogram_per_hectare, :at => r.intervention_started_at) if r.product_input_approved_dose_per_hectare

           else

            variant = ProductNatureVariant.import_from_nomenclature(:fungicide)

            intrant = variant.generate(r.product_name, r.intervention_started_at, plant.container)
              unless intrant.frozen_indicators_list.include?(:population)
                intrant.read!(:population, r.product_input_population, :at => intervention_started_at)
              end
              intrant.read!(:wait_before_harvest_period, r.dar.in_day, :at => intervention_started_at) if r.dar
              intrant.read!(:approved_input_dose, r.product_input_approved_dose_per_hectare.in_kilogram_per_hectare, :at => intervention_started_at) if r.product_input_approved_dose_per_hectare


          end

          if procedures_transcode[r.procedure_name] and intrant
          #
          # create intervention
          #
            if procedures_transcode[r.procedure_name] == :mineral_fertilizing
                        # Mineral fertilizing
                        intervention = Ekylibre::FirstRun::Booker.intervene(:mineral_fertilizing, intervention_year, intervention_month, intervention_day, 0.96 * coeff, support: support) do |i|
                          i.add_cast(reference_name: 'fertilizer',  actor: intrant)
                          i.add_cast(reference_name: 'fertilizer_to_spread', population: r.product_input_population)
                          i.add_cast(reference_name: 'spreader',    actor: i.find(Product, can: "spread(preparation)"))
                          i.add_cast(reference_name: 'driver',      actor: i.find(Worker))
                          i.add_cast(reference_name: 'tractor',     actor: i.find(Product, can: "tow(spreader)"))
                          i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                        end

            elsif procedures_transcode[r.procedure_name] == :organic_fertilizing

                      # Organic fertilizing
                      intervention = Ekylibre::FirstRun::Booker.intervene(:organic_fertilizing, intervention_year, intervention_month, intervention_day, 0.96 * coeff, support: support) do |i|
                        i.add_cast(reference_name: 'manure',      actor: intrant)
                        i.add_cast(reference_name: 'manure_to_spread', population: r.product_input_population)
                        i.add_cast(reference_name: 'spreader',    actor: i.find(Product, can: "spread(preparation)"))
                        i.add_cast(reference_name: 'driver',      actor: i.find(Worker))
                        i.add_cast(reference_name: 'tractor',     actor: i.find(Product, can: "tow(spreader)"))
                        i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                      end

            elsif procedures_transcode[r.procedure_name] == :chemical_weed

                      # Chemical weed
                      intervention = Ekylibre::FirstRun::Booker.intervene(:chemical_weed, intervention_year, intervention_month, intervention_day, 1.07 * coeff, support: support, parameters: {readings: {"base-chemical_weed-0-800-1" => "covered"}}) do |i|
                        i.add_cast(reference_name: 'weedkilling',      actor: intrant)
                        i.add_cast(reference_name: 'weedkilling_to_spray', population: r.product_input_population)
                        i.add_cast(reference_name: 'sprayer',    actor: i.find(Product, can: "spray"))
                        i.add_cast(reference_name: 'driver',      actor: i.find(Worker))
                        i.add_cast(reference_name: 'tractor',     actor: i.find(Product, can: "catch"))
                        i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                      end


            elsif procedures_transcode[r.procedure_name] == :spraying_on_cultivation

                      # Spraying on cultivation
                      intervention = Ekylibre::FirstRun::Booker.intervene(:spraying_on_cultivation, intervention_year, intervention_month, intervention_day, 1.07 * coeff, support: support) do |i|
                          i.add_cast(reference_name: 'plant_medicine', actor: intrant)
                          i.add_cast(reference_name: 'plant_medicine_to_spray', population: r.product_input_population)
                          i.add_cast(reference_name: 'sprayer',  actor: i.find(Product, can: "spray"))
                          i.add_cast(reference_name: 'driver',   actor: i.find(Worker))
                          i.add_cast(reference_name: 'tractor',  actor: i.find(Product, can: "catch"))
                          i.add_cast(reference_name: 'cultivation', actor: plant)
                        end

            else

              puts "Intervention is in a black hole".red

            end

            if intervention
              intervention.description = information_import_context + " - " +  row[4].to_s + " - operation : " + row[6].to_s + " - support : " + row[1].to_s + " - intrant : " + row[7].to_s
              intervention.save!
              puts "Intervention n°#{intervention.id} - #{intervention.name} has been created".green
            end


          end

          # create an issue if mentionned
          if r.incident_name and nature = issue_natures_transcode[r.incident_name]
            issue = Issue.create!(target_type: plant.class.name, target_id: plant.id, priority: 3, observed_at: intervention_started_at, name: r.incident_name, nature: nature, state: "closed")
            if intervention and issue
              intervention.issue = issue
              intervention.save!
            end
          end

        end
        w.check_point
      end

    end

  end



  end

  # load interventions from isaculture

  procedures_transcode = {}.with_indifferent_access

  path = loader.path("isaculture", "procedures_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      procedures_transcode[row[0]] = row[1].to_sym
    end
  end

  cultivable_zones_transcode = {}.with_indifferent_access

  path = loader.path("isaculture", "cultivable_zones_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      cultivable_zones_transcode[row[0]] = row[1]
    end
  end

  variants_transcode = {}.with_indifferent_access

  path = loader.path("isaculture", "variants_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      variants_transcode[row[0]] = row[1].to_sym
    end
  end

  units_transcode = {}.with_indifferent_access

  path = loader.path("isaculture", "units_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      units_transcode[row[0]] = row[1].to_sym
      units_transcode[row[1]] = row[2].to_sym
    end
  end

  workers_transcode = {}.with_indifferent_access

  path = loader.path("isaculture", "workers_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      workers_transcode[row[0]] = row[1]
    end
  end

  equipments_transcode = {}.with_indifferent_access

  path = loader.path("isaculture", "equipments_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      equipments_transcode[row[0]] = row[1]
    end
  end


  path = loader.path("isaculture", "interventions.csv")
  if path.exist?
    loader.count :isaculture_intervention_import do |w|


      # 0 "numero intervention"
      # 1 "code parcelle culturale"
      # 2 "parcelles cult et ateliers"
      # 3 "surface parcelle"
      # 4 "surface travaillee"
      # 5 "unite surface"
      # 6 "date debut intervention"
      # 7 "date fin intervention" ; "stade vegetatif";"realisee"
      # 10 "operation" ; "duree d operation";"volume total de bouillie";"volume de bouillie   unite surface";"code intrant";
      # 15 "intrant"
      # 16 "dose intrant"
      # 17 "unite intrant";"concentration intrant dans la bouillie";"numero de lot";"pmg";"densite de semis";
      # 22 "produit recolte";"criteres de recolte";
      # 24 "rendement"
      # 25 "unite produit";"materiel";"temps materiel";"nom et prenom main d oeuvre";"temps main d oeuvre";"motivation";"commentaire motivation";"commentaire 1";"commentaire 2"
      #

      # TODO refactor method according file structure because one intervention is on 4 or 5 lines
      # need to group and merge csv row before
      buffer = []
      current_intervention = nil

      information_import_context = "Import from isaculture on #{Time.now.l}"

      CSV.read(path, headers: true, col_sep: ";").sort{|a,b| a[6].split(/\D/).reverse.join <=> b[6].split(/\D/).reverse.join }.each do |row|
      #CSV.foreach(path, headers: true, col_sep: ";") do |row|
        if current_intervention == nil
          current_intervention = row[0] + row[1]
          buffer = row
        elsif current_intervention == row[0] + row[1]
          (0..row.size).each do |cell|
            if buffer[cell] != row[cell]
              buffer[cell] = [buffer[cell], row[cell]].join(';')
            end
          end
        else
          # manage
          #puts buffer.inspect.red

                  r = OpenStruct.new(  intervention_number: buffer[0].to_s.downcase,
                                       cultivable_zone_code: buffer[1].to_s.downcase,
                                       production_informations: buffer[2].to_s.downcase,
                                       working_area: buffer[4].gsub(",",".").to_d,
                                       unit_name: buffer[5].to_s.downcase,
                                       intervention_started_at: (buffer[6].blank? ? nil : Date.strptime(buffer[6].to_s, "%d/%m/%Y")),
                                       intervention_stopped_at: (buffer[7].blank? ? nil : Date.strptime(buffer[7].to_s, "%d/%m/%Y")),
                                       procedure_name: buffer[10].to_s.downcase, # to transcode
                                       intervention_duration_in_hour: (buffer[11].blank? ? nil : buffer[11].gsub(",",".").to_d),
                                       # one or more intrant_product could be in each buffer cell
                                       products_name: (buffer[15].blank? ? nil : buffer[15].split(';').reject(&:empty?)), #.gsub(",","_").to_s.downcase
                                       products_input_population: (buffer[16].blank? ? nil : buffer[16].split(';').reject(&:empty?)), #.gsub(",",".").to_d
                                       products_input_unit: (buffer[17].blank? ? nil : buffer[17].split(';').reject(&:empty?)), #.to_s.downcase
                                       # one or more extrant_product could be in each buffer cell
                                       extrants_name: (buffer[22].blank? ? nil : buffer[22].split(';').reject(&:empty?)),
                                       extrants_population: (buffer[24].blank? ? nil : buffer[24].split(';').reject(&:empty?)), #
                                       extrants_population_unit: (buffer[25].blank? ? nil : buffer[25].split(';').reject(&:empty?)),
                                       equipments_name: (buffer[26].blank? ? nil : buffer[26].split(';').reject(&:empty?)),
                                       workers_name: (buffer[28].blank? ? nil : buffer[28].split(';').reject(&:empty?))
                                       )

                # for intrants
                products_array = []
                if r.products_name
                  (0..r.products_name.length).each do |product_index|
                    if r.products_name[product_index] != nil
                      arr = []
                      arr << r.products_name[product_index]
                      arr << r.products_input_population[product_index]
                      arr << r.products_input_unit[product_index]
                      products_array << arr
                    end
                  end
                end

                #puts products_array.inspect.blue

                intervention_started_at = r.intervention_started_at.to_time + 9.hours
                if r.intervention_duration
                  intervention_stopped_at = intervention_started_at + r.intervention_duration.hours
                else
                  intervention_stopped_at = intervention_started_at + 2.hours
                end

                intervention_year = intervention_started_at.year
                intervention_month = intervention_started_at.month
                intervention_day = intervention_started_at.day

                production_array = r.production_informations.gsub("/",",").split(",").map(&:strip)

                campaign = Campaign.find_by_harvest_year(production_array[1])
                campaign ||= Campaign.create!(name: production_array[1], harvest_year: production_array[1])

                cultivable_zone = CultivableZone.find_by_work_number(cultivable_zones_transcode[r.cultivable_zone_code])

                equipments_work_number = nil
                if r.equipments_name
                  equipments_work_number = []
                  for equipment_name in r.equipments_name
                    equipment = Equipment.find_by_work_number(equipments_transcode[equipment_name.to_s])
                    equipments_work_number << equipment.work_number if equipment
                  end
                  equipments_work_number.compact!
                end

                workers_work_number = nil
                if r.workers_name
                  workers_work_number = []
                  for worker_name in r.workers_name
                    worker = Worker.find_by_work_number(workers_transcode[worker_name.to_s.downcase])
                    workers_work_number << worker.work_number if worker
                  end
                  workers_work_number.compact!
                end

                plant = nil
                if cultivable_zone and campaign
                  # find support
                  support = ProductionSupport.where(storage: cultivable_zone).of_campaign(campaign).first
                  # find variant link to production
                  plant_variant = support.production.variant if support
                  # try to find the current plant on cultivable zone if exist
                  cultivable_zone_shape = Charta::Geometry.new(cultivable_zone.shape)
                  if product_around = cultivable_zone_shape.actors_matching(nature: Plant).first
                    plant = product_around
                  end
                end

                puts "----------- #{w.count} / #{current_intervention} -----------".blue
                # puts r.product_name.inspect.green
                puts " procedure : " + procedures_transcode[r.procedure_name].inspect.green
                puts " intrants : " + products_array.inspect.yellow if products_array
                puts " cultivable_zone : " + cultivable_zone.name.inspect.yellow if cultivable_zone
                puts " plant : " + plant.name.inspect.yellow if plant
                puts " support : " + support.name.inspect.yellow if support
                puts " workers_work_number : " + workers_work_number.inspect.yellow if workers_work_number
                puts " equipments_work_number : " + equipments_work_number.inspect.yellow if equipments_work_number


                intrants = []
                for input_product in products_array
                  # input_product[0] = name
                  # input_product[0] = population
                  # input_product[0] = unit
                  # create intrant if variant exist
                  product_name = input_product[0].gsub(",","_").to_s.downcase
                  product_input_population = input_product[1].gsub(",",".").to_d if input_product[1]
                  product_input_unit = input_product[2].to_s.downcase if input_product[2]

                  if variants_transcode[product_name] and (product_input_population and product_input_unit)
                    variant = ProductNatureVariant.import_from_nomenclature(variants_transcode[product_name])
                    intrant = variant.generate(product_name, r.intervention_started_at, cultivable_zone)

                    unless intrant.frozen_indicators_list.include?(:population)
                       # transcode unit in file in a Nomen::Units.item
                       # ex: kg to kilogram
                       unit = units_transcode[product_input_unit]
                       value = product_input_population
                       if units_transcode[unit.to_s] == :population || unit == :population
                          population_value = value
                       elsif units_transcode[unit.to_s] == :net_volume || units_transcode[unit.to_s] == :net_mass
                         # create a Measure from value and unit in file
                         # ex: 182.25 kilogram
                         measure = Measure.new(value, unit)
                         # get an indicator from variant linked to indicator mentionned in transcoded file
                         # ex: kg,kilogram,net_mass in file
                         # ex: kilogram => net_mass
                         # ex: variant_indicator = variant.net_mass
                         if variant_indicator = variant.send(units_transcode[unit.to_s])
                            # convert measure to variant unit and divide by variant_indicator
                            # ex : for a wheat_seed_25kg
                            # 182.25 kilogram (converting in kilogram) / 25.00 kilogram
                            population_value = (measure.to_f(variant_indicator.unit.to_sym)) / variant_indicator.value.to_f
                         end
                      end
                      if r.working_area
                        global_intrant_value = population_value.to_d * r.working_area.to_d
                      end
                      puts " measure : " + measure.inspect.yellow
                      puts " units_transcode[unit.to_s] : " + units_transcode[unit.to_s].inspect.yellow

                      puts " intrant_population_value : " + population_value.inspect.yellow
                      puts " intrant_global_population_value : " + global_intrant_value.to_f.inspect.yellow
                      intrant.read!(:population, global_intrant_value, :at => r.intervention_started_at.to_time + 3.hours) if global_intrant_value
                    end
                    puts " intrant : " + intrant.name.inspect.yellow
                    intrants << intrant
                  end

                end


                # create extrant variant if variant exist
                if variants_transcode[r.extrant_name]
                  extrant_variant = ProductNatureVariant.import_from_nomenclature(variants_transcode[r.extrant_name])
                   unit = units_transcode[r.extrant_population_unit]
                   value = r.extrant_population
                   if unit.to_sym == :population
                      extrant_population_value = value
                   else
                     extrant_measure = Measure.new(value, unit)
                     if extrant_variant_unit = extrant_variant.send(units_transcode[unit.to_s]).unit
                       extrant_population_value = extrant_measure.to_f(extrant_variant_unit.to_sym)
                     end
                     if extrant_variant_indicator = extrant_variant.send(units_transcode[unit.to_s])
                        extrant_population_value = (extrant_measure.to_f(extrant_variant_indicator.unit.to_sym)) / extrant_variant_indicator.value.to_f
                     end
                   end
                    if r.working_area
                      global_extrant_value = extrant_population_value.to_d * r.working_area.to_d
                    end
                    puts " extrant_measure : " + extrant_measure.inspect.yellow
                    puts " extrant_population_value : " + extrant_population_value.inspect.yellow
                    puts " global_extrant_value : " + global_extrant_value.to_f.inspect.yellow

                  puts " extrant_variant : " + extrant_variant.name.inspect.yellow
                end




                if procedures_transcode[r.procedure_name] and support

                  Ekylibre::FirstRun::Booker.production = support.production
                  coeff = (r.working_area / 10000.0) / 6.0
                  #
                  # create intervention
                  #
                  for intrant in intrants


                    if (procedures_transcode[r.procedure_name] == :mineral_fertilizing || procedures_transcode[r.procedure_name] == :sowing) and intrant and intrant.able_to?("fertilize")
                                # Mineral fertilizing
                                intervention = Ekylibre::FirstRun::Booker.intervene(:mineral_fertilizing, intervention_year, intervention_month, intervention_day, (r.intervention_duration? ? r.intervention_duration : (0.96 * coeff)), support: support) do |i|
                                  i.add_cast(reference_name: 'fertilizer',  actor: intrant)
                                  i.add_cast(reference_name: 'fertilizer_to_spread', population: global_intrant_value)
                                  i.add_cast(reference_name: 'spreader',    actor: (equipments_work_number ? i.find(Product, of_work_numbers: equipments_work_number, can: "spread(preparation)") : i.find(Product, can: "spread(preparation)")))
                                  i.add_cast(reference_name: 'driver',      actor: (workers_work_number ? i.find(Worker, of_work_numbers: workers_work_number) : i.find(Worker)))
                                  i.add_cast(reference_name: 'tractor',     actor: (equipments_work_number ? i.find(Product, of_work_numbers: equipments_work_number, can: "tow(spreader)") : i.find(Product, can: "tow(spreader)")))
                                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                                end

                    elsif procedures_transcode[r.procedure_name] == :organic_fertilizing and intrant

                              # Organic fertilizing
                              intervention = Ekylibre::FirstRun::Booker.intervene(:organic_fertilizing, intervention_year, intervention_month, intervention_day, (r.intervention_duration? ? r.intervention_duration : (0.96 * coeff)), support: support) do |i|
                                i.add_cast(reference_name: 'manure',      actor: intrant)
                                i.add_cast(reference_name: 'manure_to_spread', population: global_intrant_value)
                                i.add_cast(reference_name: 'spreader',    actor: i.find(Product, can: "spread(preparation)"))
                                i.add_cast(reference_name: 'driver',      actor: (workers_work_number ? i.find(Worker, of_work_numbers: workers_work_number) : i.find(Worker)))
                                i.add_cast(reference_name: 'tractor',     actor: i.find(Product, can: "tow(spreader)"))
                                i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                              end

                    elsif procedures_transcode[r.procedure_name] == :chemical_weed and intrant

                              # Chemical weed
                              intervention = Ekylibre::FirstRun::Booker.intervene(:chemical_weed, intervention_year, intervention_month, intervention_day, (r.intervention_duration? ? r.intervention_duration : (1.07 * coeff)), support: support, parameters: {readings: {"base-chemical_weed-0-800-1" => "nude"}}) do |i|
                                i.add_cast(reference_name: 'weedkilling',      actor: intrant)
                                i.add_cast(reference_name: 'weedkilling_to_spray', population: global_intrant_value)
                                i.add_cast(reference_name: 'sprayer',    actor: i.find(Product, can: "spray"))
                                i.add_cast(reference_name: 'driver',      actor: (workers_work_number ? i.find(Worker, of_work_numbers: workers_work_number) : i.find(Worker)))
                                i.add_cast(reference_name: 'tractor',     actor: i.find(Product, can: "catch"))
                                i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                              end


                    elsif procedures_transcode[r.procedure_name] == :spraying_on_cultivation and intrant and plant

                              # Spraying on cultivation
                              #puts plant.container.inspect.red

                              intervention = Ekylibre::FirstRun::Booker.intervene(:spraying_on_cultivation, intervention_year, intervention_month, intervention_day, (r.intervention_duration? ? r.intervention_duration : (1.07 * coeff)), support: support) do |i|
                                  i.add_cast(reference_name: 'plant_medicine', actor: intrant)
                                  i.add_cast(reference_name: 'plant_medicine_to_spray', population: global_intrant_value)
                                  i.add_cast(reference_name: 'sprayer',  actor: i.find(Product, can: "spray"))
                                  i.add_cast(reference_name: 'driver',   actor: (workers_work_number ? i.find(Worker, of_work_numbers: workers_work_number) : i.find(Worker)))
                                  i.add_cast(reference_name: 'tractor',  actor: i.find(Product, can: "catch"))
                                  i.add_cast(reference_name: 'cultivation', actor: plant)
                                end

                    elsif procedures_transcode[r.procedure_name] == :spraying_on_land_parcel and intrant

                              # Spraying on cultivation
                              intervention = Ekylibre::FirstRun::Booker.intervene(:spraying_on_land_parcel, intervention_year, intervention_month, intervention_day, (r.intervention_duration? ? r.intervention_duration : (1.07 * coeff)), support: support) do |i|
                                  i.add_cast(reference_name: 'plant_medicine', actor: intrant)
                                  i.add_cast(reference_name: 'plant_medicine_to_spray', population: global_intrant_value)
                                  i.add_cast(reference_name: 'sprayer',  actor: i.find(Product, can: "spray"))
                                  i.add_cast(reference_name: 'driver',   actor: (workers_work_number ? i.find(Worker, of_work_numbers: workers_work_number) : i.find(Worker)))
                                  i.add_cast(reference_name: 'tractor',  actor: i.find(Product, can: "catch"))
                                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                                end

                    elsif procedures_transcode[r.procedure_name] == :sowing and intrant and plant_variant and intrant.able_to?("grow")

                              # Spraying on cultivation
                              intervention = Ekylibre::FirstRun::Booker.intervene(:sowing, intervention_year, intervention_month, intervention_day, (r.intervention_duration? ? r.intervention_duration : (1.07 * coeff)), support: support, parameters: {readings: {"base-sowing-0-750-2" => global_intrant_value.to_i}}) do |i|

                                  i.add_cast(reference_name: 'seeds',        actor: intrant)
                                  i.add_cast(reference_name: 'seeds_to_sow', population: global_intrant_value)
                                  i.add_cast(reference_name: 'sower',        actor: i.find(Product, can: "sow"))
                                  i.add_cast(reference_name: 'driver',       actor: (workers_work_number ? i.find(Worker, of_work_numbers: workers_work_number) : i.find(Worker)))
                                  i.add_cast(reference_name: 'tractor',      actor: i.find(Product, can: "tow(sower)"))
                                  i.add_cast(reference_name: 'land_parcel',  actor: cultivable_zone)
                                  i.add_cast(reference_name: 'cultivation',  variant: plant_variant, population: r.working_area, shape: cultivable_zone.shape)

                                end





                    else procedures_transcode[r.procedure_name] == :watering and plant and intrant and intrant.variety == 'water'

                              # Watering
                              intervention = Ekylibre::FirstRun::Booker.intervene(:watering, intervention_year, intervention_month, intervention_day, (r.intervention_duration? ? r.intervention_duration : (1.07 * coeff)), support: support) do |i|

                                  i.add_cast(reference_name: 'water',           actor: intrant)
                                  i.add_cast(reference_name: 'water_to_spread', population: global_intrant_value)
                                  i.add_cast(reference_name: 'spreader',        actor: i.find(Product, can: "spread(water)"))
                                  i.add_cast(reference_name: 'driver',       actor: (workers_work_number ? i.find(Worker, of_work_numbers: workers_work_number) : i.find(Worker)))
                                  i.add_cast(reference_name: 'land_parcel',  actor: cultivable_zone)
                                  i.add_cast(reference_name: 'cultivation',  actor: plant , population: r.working_area, shape: plant.shape)

                                end



                    end



                  end




                  if procedures_transcode[r.procedure_name] == :grains_harvest and extrant_variant and extrant_variant.variety == "silage" and plant

                              # Silage
                              intervention = Ekylibre::FirstRun::Booker.intervene(:direct_silage, intervention_year, intervention_month, intervention_day, (r.intervention_duration? ? r.intervention_duration : (3.13 * coeff)), support: support) do |i|
                              i.add_cast(reference_name: 'forager',        actor: i.find(Product, can: "harvest(plant)"))
                              i.add_cast(reference_name: 'forager_driver', actor: (workers_work_number ? i.find(Worker, of_work_numbers: workers_work_number) : i.find(Worker)))
                              i.add_cast(reference_name: 'cultivation',    actor: plant)
                              i.add_cast(reference_name: 'silage',         population: global_extrant_value, variant: extrant_variant)
                                end



                  elsif procedures_transcode[r.procedure_name] == :grains_harvest and extrant_variant and plant

                              straw_variant = ProductNatureVariant.find_or_import!(:straw, derivative_of: plant.variety).first
                              straw_variant ||= ProductNatureVariant.import_from_nomenclature(:crop_residue)

                              # Grain harvest
                              intervention = Ekylibre::FirstRun::Booker.intervene(:grains_harvest, intervention_year, intervention_month, intervention_day, (r.intervention_duration? ? r.intervention_duration : (3.13 * coeff)), support: support) do |i|
                              i.add_cast(reference_name: 'cropper',        actor: i.find(Product, can: "harvest(poaceae)"))
                              i.add_cast(reference_name: 'cropper_driver', actor: (workers_work_number ? i.find(Worker, of_work_numbers: workers_work_number) : i.find(Worker)))
                              i.add_cast(reference_name: 'cultivation',    actor: plant)
                              i.add_cast(reference_name: 'grains',         population: global_extrant_value, variant: extrant_variant)
                              i.add_cast(reference_name: 'straws',         population: global_extrant_value / 10, variant: straw_variant)
                                end




                  end

                  if intervention
                    intervention.description = information_import_context + " - N° : " + r.intervention_number + " - " +  row[6].to_s + " - operation : " + row[10].to_s + " - support : " + row[1].to_s + " - intrant : " + row[15].to_s
                    intervention.save!
                    puts "Intervention n°#{intervention.id} - #{intervention.name} has been created".green
                  else
                    puts "Intervention is in a black hole".red
                  end

                end







          w.check_point
          # then change intervention
          buffer = row
          current_intervention = row[0] + row[1]

        end

      end
    end

  end


end
