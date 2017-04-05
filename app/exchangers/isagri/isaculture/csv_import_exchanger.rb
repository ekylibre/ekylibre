# coding: utf-8

module Isagri
  module Isaculture
    class CsvImportExchanger < ActiveExchanger::Base
      def import
        # Unzip file
        dir = w.tmp_dir
        Zip::File.open(file) do |zile|
          zile.each do |entry|
            entry.extract(dir.join(entry.name))
          end
        end

        # load interventions from isaculture

        procedures_transcode = {}.with_indifferent_access
        path = dir.join('procedures_transcode.csv')
        if path.exist?
          CSV.foreach(path, headers: true) do |row|
            procedures_transcode[row[0]] = row[1].to_sym
          end
        end

        cultivable_zones_transcode = {}.with_indifferent_access
        path = dir.join('cultivable_zones_transcode.csv')
        if path.exist?
          CSV.foreach(path, headers: true) do |row|
            cultivable_zones_transcode[row[0]] = row[1]
          end
        end

        variants_transcode = {}.with_indifferent_access
        path = dir.join('variants_transcode.csv')
        if path.exist?
          CSV.foreach(path, headers: true) do |row|
            variants_transcode[row[0]] = row[1].to_sym
          end
        end

        units_transcode = {}.with_indifferent_access
        path = dir.join('units_transcode.csv')
        if path.exist?
          CSV.foreach(path, headers: true) do |row|
            units_transcode[row[0]] = row[1].to_sym
            units_transcode[row[1]] = row[2].to_sym
          end
        end

        workers_transcode = {}.with_indifferent_access
        path = dir.join('workers_transcode.csv')
        if path.exist?
          CSV.foreach(path, headers: true) do |row|
            workers_transcode[row[0]] = row[1]
          end
        end

        equipments_transcode = {}.with_indifferent_access
        path = dir.join('equipments_transcode.csv')
        if path.exist?
          CSV.foreach(path, headers: true) do |row|
            equipments_transcode[row[0]] = row[1]
          end
        end

        path = dir.join('interventions.csv')
        if path.exist?

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

          buffer = []
          current_intervention = nil

          information_import_context = "Import from isaculture on #{Time.zone.now.l}"

          source = File.read(path)
          detection = CharlockHolmes::EncodingDetector.detect(source)
          w.info "Detected encoding: #{detection.inspect}"

          source = File.read(path, encoding: detection[:encoding])
          stats = ["\t", ';', ',', '|'].each_with_object({}) do |char, hash|
            hash[char] = source.count(char)
            hash
          end
          separator = stats.sort { |a, b| b.second <=> a.second }.first.first
          w.info "Detected separator: '#{separator}'"

          rows = CSV.read(path, headers: true, col_sep: separator, encoding: detection[:encoding]).sort do |a, b|
            [a[6].split(/\D/).reverse.join, a[0].to_s, a[1].to_s] <=> [b[6].split(/\D/).reverse.join, b[0].to_s, b[1].to_s]
          end
          w.count = rows.size

          rows.each do |row|
            # CSV.foreach(path, headers: true, col_sep: ";") do |row|
            w.check_point
            next if row[1].blank?
            if current_intervention.nil?
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
              r = OpenStruct.new(
                intervention_number: buffer[0].to_s.downcase,
                cultivable_zone_code: buffer[1].to_s.downcase,
                production_informations: buffer[2].to_s.downcase,
                working_area: buffer[4].tr(',', '.').to_d,
                unit_name: buffer[5].to_s.downcase,
                intervention_started_at: (buffer[6].blank? ? nil : Date.strptime(buffer[6].to_s, '%d/%m/%Y')),
                intervention_stopped_at: (buffer[7].blank? ? nil : Date.strptime(buffer[7].to_s, '%d/%m/%Y')),
                procedure_name: buffer[10].to_s.downcase, # to transcode
                intervention_duration_in_hour: (buffer[11].blank? ? nil : buffer[11].tr(',', '.').to_d),
                # one or more intrant_product could be in each buffer cell
                products_code: (buffer[14].blank? ? nil : buffer[14].split(';').reject(&:empty?)), # .gsub(",","_").to_s.downcase
                products_name: (buffer[15].blank? ? nil : buffer[15].split(';').reject(&:empty?)), # .gsub(",","_").to_s.downcase
                products_input_population: (buffer[16].blank? ? nil : buffer[16].split(';').reject(&:empty?)), # .gsub(",",".").to_d
                products_input_unit: (buffer[17].blank? ? nil : buffer[17].split(';').reject(&:empty?)), # .to_s.downcase
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
                  next if r.products_name[product_index].nil?
                  arr = []
                  arr << r.products_name[product_index]
                  arr << r.products_input_population[product_index]
                  arr << r.products_input_unit[product_index]
                  arr << r.products_code[product_index] if r.products_code
                  products_array << arr
                end
              end

              # for extrants
              extrants_array = []
              if r.extrants_name
                (0..r.extrants_name.length).each do |extrant_index|
                  next if r.extrants_name[extrant_index].nil?
                  arr = []
                  arr << r.extrants_name[extrant_index]
                  arr << r.extrants_population[extrant_index]
                  arr << r.extrants_population_unit[extrant_index]
                  extrants_array << arr
                end
              end

              intervention_started_at = r.intervention_started_at.to_time + 9.hours
              duration_in_seconds = r.intervention_duration_in_hour.hours
              intervention_stopped_at = if duration_in_seconds
                                          intervention_started_at + duration_in_seconds
                                        else
                                          intervention_started_at + 2.hours
                                        end

              intervention_year = intervention_started_at.year
              intervention_month = intervention_started_at.month
              intervention_day = intervention_started_at.day

              production_array = r.production_informations.tr('/', ',').split(',').map(&:strip)

              campaign = Campaign.find_by(harvest_year: production_array[1])
              campaign ||= Campaign.create!(name: production_array[1], harvest_year: production_array[1])

              cultivable_zone = CultivableZone.find_by(work_number: cultivable_zones_transcode[r.cultivable_zone_code])

              equipments_work_number = []
              if r.equipments_name
                for equipment_name in r.equipments_name
                  equipment = Equipment.find_by(work_number: equipments_transcode[equipment_name.to_s])
                  equipments_work_number << equipment.work_number if equipment
                end
                equipments_work_number.compact!
              end

              workers_work_number = []
              if r.workers_name
                for worker_name in r.workers_name
                  worker = Worker.find_by(work_number: workers_transcode[worker_name.to_s.downcase])
                  workers_work_number << worker.work_number if worker
                end
                workers_work_number.compact!
              end

              plant = nil
              if cultivable_zone && campaign
                # find support
                support = ActivityProduction.where(storage: cultivable_zone).of_campaign(campaign).first
                # find variant link to production
                plant_variant = support.production.variant if support
                # try to find the current plant on cultivable zone if exist
                cultivable_zone_shape = Charta.new_geometry(cultivable_zone.shape)
                if product_around = Plant.within_shape(cultivable_zone_shape).first
                  plant = product_around
                end
              end

              w.debug "----------- #{current_intervention} -----------".blue
              w.debug ' procedure : ' + procedures_transcode[r.procedure_name].inspect.green
              w.debug ' started_at : ' + intervention_started_at.inspect.yellow if intervention_started_at
              w.debug ' duration : ' + duration_in_seconds.inspect.yellow if duration_in_seconds
              w.debug ' intrants : ' + products_array.inspect.yellow if products_array
              w.debug ' cultivable_zone : ' + cultivable_zone.name.inspect.yellow + ' - ' + cultivable_zone.work_number.inspect.yellow if cultivable_zone
              w.debug ' plant : ' + plant.name.inspect.yellow if plant
              w.debug ' support : ' + support.name.inspect.yellow if support
              w.debug ' workers_work_number : ' + workers_work_number.inspect.yellow if workers_work_number
              w.debug ' equipments_work_number : ' + equipments_work_number.inspect.yellow if equipments_work_number

              intrants = []
              for input_product in products_array
                # input_product[0] = name
                # input_product[0] = population
                # input_product[0] = unit
                # create intrant if variant exist
                product_name = input_product[0].tr(',', '_').to_s.downcase
                product_input_population = input_product[1].tr(',', '.').to_d if input_product[1]
                product_input_unit = input_product[2].to_s.downcase if input_product[2]
                product_input_code = input_product[3].to_s if input_product[3]

                next unless variants_transcode[product_name] && (product_input_population && product_input_unit)
                variant = ProductNatureVariant.import_from_nomenclature(variants_transcode[product_name])
                intrant = variant.generate(product_name, r.intervention_started_at, cultivable_zone)

                unless intrant.frozen_indicators_list.include?(:population)
                  # transcode unit in file in a Nomen::Unit.item
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
                      population_value = measure.to_f(variant_indicator.unit.to_sym) / variant_indicator.value.to_f
                    end
                  end
                  if r.working_area
                    global_intrant_value = population_value.to_d * r.working_area.to_d
                  end
                  w.debug ' measure : ' + measure.inspect.yellow
                  w.debug ' units_transcode[unit.to_s] : ' + units_transcode[unit.to_s].inspect.yellow
                  w.debug ' intrant_population_value : ' + population_value.inspect.yellow
                  w.debug ' intrant_global_population_value : ' + global_intrant_value.to_f.inspect.yellow
                  intrant.read!(:population, global_intrant_value, at: r.intervention_started_at.to_time + 3.hours) if global_intrant_value
                  intrant.identification_number = product_input_code if product_input_code
                  intrant.save!
                end
                w.debug ' intrant : ' + intrant.name.inspect.yellow
                intrants << intrant

              end

              extrants = []
              for extrant_product in extrants_array
                # input_product[0] = name
                # input_product[0] = population
                # input_product[0] = unit
                # create intrant if variant exist
                extrant_name = extrant_product[0].tr(',', '_').to_s.downcase
                extrant_population = extrant_product[1].tr(',', '.').to_d if extrant_product[1]
                extrant_unit = extrant_product[2].to_s.downcase if extrant_product[2]
                # create extrant variant if variant exist
                next unless variants_transcode[extrant_name]
                extrant_variant = ProductNatureVariant.import_from_nomenclature(variants_transcode[extrant_name])
                unit = units_transcode[extrant_unit]
                value = extrant_population
                if unit.to_sym == :population
                  extrant_population_value = value
                else
                  extrant_measure = Measure.new(value, unit)
                  if extrant_variant_unit = extrant_variant.send(units_transcode[unit.to_s]).unit
                    extrant_population_value = extrant_measure.to_f(extrant_variant_unit.to_sym)
                  end
                  if extrant_variant_indicator = extrant_variant.send(units_transcode[unit.to_s])
                    extrant_population_value = extrant_measure.to_f(extrant_variant_indicator.unit.to_sym) / extrant_variant_indicator.value.to_f
                  end
                end
                if r.working_area
                  global_extrant_value = extrant_population_value.to_d * r.working_area.to_d
                end
                w.debug ' extrant_measure : ' + extrant_measure.inspect.yellow
                w.debug ' extrant_population_value : ' + extrant_population_value.inspect.yellow
                w.debug ' global_extrant_value : ' + global_extrant_value.to_f.inspect.yellow

                w.debug ' extrant_variant : ' + extrant_variant.name.inspect.yellow
                extrants << { extrant_variant: extrant_variant, global_extrant_value: global_extrant_value }

              end

              coeff = ((r.working_area / 10_000.0) / 6.0).to_d

              if procedures_transcode[r.procedure_name] && support && (coeff.to_f > 0.0)

                Ekylibre::FirstRun::Booker.production = support.production

                #
                # create intervention without intrant(s)
                #

                if procedures_transcode[r.procedure_name] == :raking
                  # Raking

                  intervention = Ekylibre::FirstRun::Booker.force(:raking, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (2.96 * coeff.to_f)), support: support, parameters: { readings: { 'base-raking-0-1-readstate' => 'plowed' } }) do |i|
                    i.add_cast(reference_name: 'harrow',      actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'plow_superficially') : i.find(Equipment, can: 'plow_superficially')))
                    i.add_cast(reference_name: 'driver',      actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                    i.add_cast(reference_name: 'tractor',     actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(equipment)')))
                    i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                  end

                elsif procedures_transcode[r.procedure_name] == :grinding

                  intervention = Ekylibre::FirstRun::Booker.force(:grinding, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (2.96 * coeff.to_f)), support: support) do |i|
                    i.add_cast(reference_name: 'grinder', actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'grind(plant)') : i.find(Equipment, can: 'grind(plant)')))
                    i.add_cast(reference_name: 'driver',      actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                    i.add_cast(reference_name: 'tractor',     actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(equipment)')))
                    i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                  end

                elsif procedures_transcode[r.procedure_name] == :cutting && plant

                  intervention = Ekylibre::FirstRun::Booker.force(:cutting, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (2.96 * coeff.to_f)), support: support) do |i|
                    i.add_cast(reference_name: 'cutter',      actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'cut') : i.find(Equipment, can: 'cut')))
                    i.add_cast(reference_name: 'driver',      actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                    i.add_cast(reference_name: 'tractor',     actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'catch(equipment)') : i.find(Equipment, can: 'catch(equipment)')))
                    i.add_cast(reference_name: 'cultivation', actor: plant)
                  end

                elsif procedures_transcode[r.procedure_name] == :administrative_task

                  intervention = Ekylibre::FirstRun::Booker.force(:administrative_task, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (0.15 * coeff.to_f)), support: support) do |i|
                    i.add_cast(reference_name: 'worker', actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                  end

                elsif procedures_transcode[r.procedure_name] == :maintenance_task && plant

                  intervention = Ekylibre::FirstRun::Booker.force(:maintenance_task, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (0.15 * coeff.to_f)), support: support) do |i|
                    i.add_cast(reference_name: 'worker', actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                    i.add_cast(reference_name: 'maintained', actor: plant)
                  end

                end

                #
                # create intervention with intrant(s)
                #

                for intrant in intrants

                  if (procedures_transcode[r.procedure_name] == :mineral_fertilizing || procedures_transcode[r.procedure_name] == :sowing) && intrant && intrant.able_to?('fertilize')
                    # Mineral fertilizing

                    intervention = Ekylibre::FirstRun::Booker.force(:mineral_fertilizing, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (0.96 * coeff.to_f)), support: support) do |i|
                      i.add_cast(reference_name: 'fertilizer', actor: intrant)
                      i.add_cast(reference_name: 'fertilizer_to_spread', population: intrant.population)
                      i.add_cast(reference_name: 'spreader',    actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'spread(preparation)') : i.find(Equipment, can: 'spread(preparation)')))
                      i.add_cast(reference_name: 'driver',      actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                      i.add_cast(reference_name: 'tractor',     actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'tow(spreader)') : i.find(Equipment, can: 'tow(spreader)')))
                      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                    end

                  elsif procedures_transcode[r.procedure_name] == :organic_fertilizing && intrant

                    # Organic fertilizing
                    intervention = Ekylibre::FirstRun::Booker.force(:organic_fertilizing, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (0.96 * coeff.to_f)), support: support) do |i|
                      i.add_cast(reference_name: 'manure',      actor: intrant)
                      i.add_cast(reference_name: 'manure_to_spread', population: intrant.population)
                      i.add_cast(reference_name: 'spreader',    actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'spread(preparation)') : i.find(Equipment, can: 'spread(preparation)')))
                      i.add_cast(reference_name: 'driver',      actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                      i.add_cast(reference_name: 'tractor',     actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'tow(spreader)') : i.find(Equipment, can: 'tow(spreader)')))
                      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                    end

                  elsif procedures_transcode[r.procedure_name] == :chemical_weed_killing && intrant

                    # Chemical weed
                    intervention = Ekylibre::FirstRun::Booker.force(:chemical_weed_killing, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (1.07 * coeff.to_f)), support: support, parameters: { readings: { 'base-chemical_weed_killing-0-1-readstate' => 'nude' } }) do |i|
                      i.add_cast(reference_name: 'weedkiller', actor: intrant)
                      i.add_cast(reference_name: 'weedkiller_to_spray', population: intrant.population)
                      i.add_cast(reference_name: 'sprayer',     actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'spray') : i.find(Equipment, can: 'spray')))
                      i.add_cast(reference_name: 'driver',      actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                      i.add_cast(reference_name: 'tractor',     actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'catch(sprayer)') : i.find(Equipment, can: 'catch(sprayer)')))
                      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                    end

                  elsif procedures_transcode[r.procedure_name] == :spraying_on_cultivation && intrant && plant

                    # Spraying on cultivation
                    # w.debug plant.container.inspect.red

                    intervention = Ekylibre::FirstRun::Booker.force(:spraying_on_cultivation, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (1.07 * coeff.to_f)), support: support) do |i|
                      i.add_cast(reference_name: 'plant_medicine', actor: intrant)
                      i.add_cast(reference_name: 'plant_medicine_to_spray', population: intrant.population)
                      i.add_cast(reference_name: 'sprayer',  actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'spray') : i.find(Equipment, can: 'spray')))
                      i.add_cast(reference_name: 'driver',   actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                      i.add_cast(reference_name: 'tractor',  actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'catch(sprayer)') : i.find(Equipment, can: 'catch(sprayer)')))
                      i.add_cast(reference_name: 'cultivation', actor: plant)
                    end

                  elsif procedures_transcode[r.procedure_name] == :spraying_on_land_parcel && intrant

                    # Spraying on cultivation
                    intervention = Ekylibre::FirstRun::Booker.force(:spraying_on_land_parcel, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (1.07 * coeff.to_f)), support: support) do |i|
                      i.add_cast(reference_name: 'plant_medicine', actor: intrant)
                      i.add_cast(reference_name: 'plant_medicine_to_spray', population: intrant.population)
                      i.add_cast(reference_name: 'sprayer',  actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'spray') : i.find(Equipment, can: 'spray')))
                      i.add_cast(reference_name: 'driver',   actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                      i.add_cast(reference_name: 'tractor',  actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'catch(sprayer)') : i.find(Equipment, can: 'catch(sprayer)')))
                      i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                    end

                  elsif procedures_transcode[r.procedure_name] == :sowing && intrant && plant_variant && intrant.able_to?('grow')

                    # Spraying on cultivation
                    intervention = Ekylibre::FirstRun::Booker.force(:sowing, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (1.07 * coeff.to_f)), support: support, parameters: { readings: { 'base-sowing-0-1-readcount' => global_intrant_value.to_i } }) do |i|
                      i.add_cast(reference_name: 'seeds',        actor: intrant)
                      i.add_cast(reference_name: 'seeds_to_sow', population: intrant.population)
                      i.add_cast(reference_name: 'sower',        actor: (equipments_work_number.count > 0 ? i.find(Equipment, work_number: equipments_work_number, can: 'sow') : i.find(Equipment, can: 'sow')))
                      i.add_cast(reference_name: 'driver',       actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                      i.add_cast(reference_name: 'tractor',      actor: i.find(Product, can: 'tow(sower)'))
                      i.add_cast(reference_name: 'land_parcel',  actor: cultivable_zone)
                      i.add_cast(reference_name: 'cultivation',  variant: plant_variant, population: r.working_area, shape: cultivable_zone.shape)
                    end

                  elsif procedures_transcode[r.procedure_name] == :watering && plant && intrant && intrant.variety == 'water'

                    # Watering
                    intervention = Ekylibre::FirstRun::Booker.force(:watering, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (1.07 * coeff.to_f)), support: support) do |i|
                      i.add_cast(reference_name: 'water',           actor: intrant)
                      i.add_cast(reference_name: 'water_to_spread', population: intrant.population)
                      i.add_cast(reference_name: 'spreader',        actor: i.find(Product, can: 'spread(water)'))
                      i.add_cast(reference_name: 'driver',       actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                      i.add_cast(reference_name: 'land_parcel',  actor: cultivable_zone)
                      i.add_cast(reference_name: 'cultivation',  actor: plant, population: r.working_area, shape: plant.shape)
                    end

                  end

                end

                #
                # create intervention with extrant(s)
                # extrant is a Hash

                for extrant in extrants
                  if procedures_transcode[r.procedure_name] == :grains_harvest && extrant[:extrant_variant] && extrant[:extrant_variant].variety == 'silage' && plant

                    # Silage
                    intervention = Ekylibre::FirstRun::Booker.force(:direct_silage, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (3.13 * coeff.to_f)), support: support) do |i|
                      i.add_cast(reference_name: 'forager',        actor: i.find(Product, can: 'harvest(plant)'))
                      i.add_cast(reference_name: 'forager_driver', actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                      i.add_cast(reference_name: 'cultivation',    actor: plant)
                      i.add_cast(reference_name: 'silage',         population: extrant[:global_extrant_value], variant: extrant[:extrant_variant])
                    end

                  elsif procedures_transcode[r.procedure_name] == :grains_harvest && extrant[:extrant_variant] && plant

                    straw_variant = ProductNatureVariant.find_or_import!(:straw, derivative_of: plant.variety).first
                    straw_variant ||= ProductNatureVariant.import_from_nomenclature(:crop_residue)

                    # Grain harvest
                    intervention = Ekylibre::FirstRun::Booker.force(:grains_harvest, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (3.13 * coeff.to_f)), support: support) do |i|
                      i.add_cast(reference_name: 'cropper',        actor: i.find(Product, can: 'harvest(poaceae)'))
                      i.add_cast(reference_name: 'cropper_driver', actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                      i.add_cast(reference_name: 'cultivation',    actor: plant)
                      i.add_cast(reference_name: 'grains',         population: extrant[:global_extrant_value], variant: extrant[:extrant_variant])
                      i.add_cast(reference_name: 'straws',         population: extrant[:global_extrant_value] / 10, variant: straw_variant)
                    end

                  elsif procedures_transcode[r.procedure_name] == :harvest && plant && extrant[:extrant_variant]
                    variety_plant = Nomen::Variety.find(plant.variety)
                    if variety_plant
                      if variety_plant <= :corylus
                        # Hazelnuts harvest
                        intervention = Ekylibre::FirstRun::Booker.force(:hazelnuts_harvest, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (3.13 * coeff.to_f)), support: support) do |i|
                          i.add_cast(reference_name: 'nuts_harvester',        actor: i.find(Product, can: 'harvest(hazelnut)'))
                          i.add_cast(reference_name: 'driver',                actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                          i.add_cast(reference_name: 'cultivation',           actor: plant)
                          i.add_cast(reference_name: 'hazelnuts',             population: extrant[:global_extrant_value], variant: extrant[:extrant_variant])
                        end

                      elsif variety_plant <= :juglans
                        # Walnuts harvest
                        intervention = Ekylibre::FirstRun::Booker.force(:walnuts_harvest, intervention_started_at, (duration_in_seconds.to_f > 0.0 ? (duration_in_seconds / 3600) : (3.13 * coeff.to_f)), support: support) do |i|
                          i.add_cast(reference_name: 'nuts_harvester',        actor: i.find(Product, can: 'harvest(walnut)'))
                          i.add_cast(reference_name: 'driver',                actor: (workers_work_number.count > 0 ? i.find(Worker, work_number: workers_work_number) : i.find(Worker)))
                          i.add_cast(reference_name: 'cultivation',           actor: plant)
                          i.add_cast(reference_name: 'walnuts', population: extrant[:global_extrant_value], variant: extrant[:extrant_variant])
                        end

                      end
                    end

                  end
                end

                if intervention
                  intervention.description = information_import_context + ' - N° : ' + r.intervention_number + ' - ' + row[6].to_s + ' - operation : ' + row[10].to_s + ' - support : ' + row[1].to_s + ' - intrant : ' + row[15].to_s
                  intervention.save!
                  w.info "Intervention n°#{intervention.id} - #{intervention.name} has been created".green
                else
                  w.info 'Intervention is in a black hole'.red
                end

              end

              # then change intervention
              buffer = row
              current_intervention = row[0] + row[1]

            end
          end
        end
      end
    end
  end
end
