module Ekylibre
  module FirstRun
    module Faker
      class Interventions < Base
        def run
          # interventions for all poaceae
          autumn_sowables = %i[poa hordeum_hibernum secale triticosecale triticum brassica_napus pisum_hibernum].collect do |n|
            Nomen::Variety[n]
          end

          spring_sowables = %i[hordeum_vernum pisum_vernum helianthus].collect do |n|
            Nomen::Variety[n]
          end

          later_spring_sowables = [:zea].collect do |n|
            Nomen::Variety[n]
          end

          GC.start

          count :cultural_interventions do |w|
            workers = Worker.all
            products = {
              manure: Product.where(variety: :manure).can('fertilize').all,
              tractor: { spreader: Product.can('tow(spreader)').all,
                         plower: Product.can('tow(plower)').all,
                         sower: Product.can('tow(sower)').all,
                         catcher: Product.can('catch(equipment)').all },
              spreader: Product.can('spread(preparation)').all,
              plow: Product.can('plow').all,
              sow: Product.can('sow').all,
              sprayer: Product.can('spray').all,
              fertilizer: Product.where(variety: :preparation).can('fertilize').all,
              plant_medicine: Product.where(variety: :preparation).can('care(plant)').all
            }
            ActivityProduction.joins(:activity).find_each do |production|
              next unless production.active?
              variety = Nomen::Variety[production.cultivation_variety]
              if autumn_sowables.detect { |v| variety <= v }
                year = production.campaign.name.to_i
                Ekylibre::FirstRun::Booker.production = production
                production.supports.joins(:storage, :activity).find_each do |support|
                  next unless support.active?
                  land_parcel = support.storage
                  next unless area = land_parcel.shape_area
                  coeff = (area.to_s.to_f / 10_000.0) / 6.0
                  # 7.99 -> 20.11 -> 40.21

                  # Organic Fertilizing  01-09-N-1 -> 30-09-N-1
                  Ekylibre::FirstRun::Booker.intervene(:organic_fertilizing, year - 1, 9, 1, 0.96 * coeff, support: support) do |i|
                    i.add_cast(reference_name: 'manure',      actor: products[:manure].sample)
                    i.add_cast(reference_name: 'manure_to_spread', population: 0.2 + 4 * coeff)
                    i.add_cast(reference_name: 'spreader',    actor: products[:spreader].sample)
                    i.add_cast(reference_name: 'driver',      actor: workers.sample)
                    i.add_cast(reference_name: 'tractor',     actor: products[:tractor][:spreader].sample)
                    i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
                  end

                  # Plowing 15-09-N -> 15-10-N
                  Ekylibre::FirstRun::Booker.intervene(:plowing, year - 1, 9, 15, 9.78 * coeff, support: support, parameters: { readings: { 'base-plowing-0-1-readstate' => 'plowed' } }) do |i|
                    i.add_cast(reference_name: 'driver',  actor: workers.sample)
                    i.add_cast(reference_name: 'tractor', actor: products[:tractor][:plower].sample)
                    i.add_cast(reference_name: 'plow',    actor: products[:plow].sample)
                    i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
                  end

                  # Sowing 15-10-N -> 30-10-N
                  int = Ekylibre::FirstRun::Booker.intervene(:sowing, year - 1, 10, 15, 6.92 * coeff, range: 15, support: support, parameters: { readings: { 'base-sowing-0-1-readcount' => 2_000_000 + rand(250_000) } }) do |i|
                    i.add_cast(reference_name: 'seeds',        actor: i.find(Product, variety: :seed, derivative_of: variety.name, can: 'grow'))
                    i.add_cast(reference_name: 'seeds_to_sow', population: rand(5) + 1)
                    i.add_cast(reference_name: 'sower',        actor: products[:sow].sample)
                    i.add_cast(reference_name: 'driver',       actor: workers.sample)
                    i.add_cast(reference_name: 'tractor',      actor: products[:tractor][:sower].sample)
                    i.add_cast(reference_name: 'land_parcel',  actor: land_parcel)
                    i.add_cast(reference_name: 'cultivation',  variant: ProductNatureVariant.find_or_import!(variety.name).first, population: (area.to_s.to_f / 10_000.0), shape: land_parcel.shape)
                  end

                  # Fertilizing  01-03-M -> 31-03-M
                  Ekylibre::FirstRun::Booker.intervene(:mineral_fertilizing, year, 3, 1, 0.96 * coeff, support: support) do |i|
                    i.add_cast(reference_name: 'fertilizer', actor: products[:fertilizer].sample)
                    i.add_cast(reference_name: 'fertilizer_to_spread', population: 0.4 + coeff * rand(0.6))
                    i.add_cast(reference_name: 'spreader',    actor: products[:spreader].sample)
                    i.add_cast(reference_name: 'driver',      actor: workers.sample)
                    i.add_cast(reference_name: 'tractor',     actor: products[:tractor][:spreader].sample)
                    i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
                  end

                  if w.count.modulo(3).zero? # AND NOT prairie
                    cultivation = int.product_parameters.find_by(reference_name: 'cultivation').actor
                    # Treatment herbicide 01-04 30-04
                    Ekylibre::FirstRun::Booker.intervene(:spraying_on_cultivation, year, 4, 1, 1.07 * coeff, support: support) do |i|
                      i.add_cast(reference_name: 'plant_medicine', actor: products[:plant_medicine].sample)
                      i.add_cast(reference_name: 'plant_medicine_to_spray', population: 0.18 + 0.9 * coeff)
                      i.add_cast(reference_name: 'sprayer',  actor: products[:sprayer].sample)
                      i.add_cast(reference_name: 'driver',   actor: workers.sample)
                      i.add_cast(reference_name: 'tractor',  actor: products[:tractor][:catcher].sample)
                      i.add_cast(reference_name: 'cultivation', actor: cultivation)
                    end
                  end
                  w.check_point
                end
              end
            end
          end
          GC.start

          count :zea_cultural_interventions do |w|
            workers = Worker.all
            products = {
              tractor: { spreader: Product.can('tow(spreader)').all,
                         plower: Product.can('tow(plower)').all,
                         sower: Product.can('tow(sower)').all,
                         equipment: Product.can('tow(equipment)').all,
                         catcher: Product.can('catch(equipment)').all },
              spreader: Product.can('spread(preparation)').all,
              plow: Product.can('plow').all,
              sprayer: Product.can('spray').all,
              fertilizer: Product.where(variety: :preparation).can('fertilize').all,
              plant_medicine: Product.where(variety: :preparation).can('care(plant)', 'kill(plant)').all,
              insecticide: Product.where(variety: :preparation).can('kill(insecta)').all,
              molluscicide: Product.where(variety: :preparation).can('kill(gastropoda)').all
            }
            equipments = {
              sower: Equipment.can('spread(preparation)', 'sow', 'spray').all,
              hoe: Equipment.can('hoe').all
            }
            Production.joins(:variant, :activity, :campaign).find_each do |production|
              next unless production.active?
              variety = Nomen::Variety[production.variant.variety]
              if later_spring_sowables.detect { |v| variety <= v }
                year = production.campaign.name.to_i
                Ekylibre::FirstRun::Booker.production = production
                production.supports.joins(:activity, :storage).find_each do |support|
                  next unless support.active?
                  land_parcel = support.storage
                  next unless area = land_parcel.shape_area
                  coeff = (area.to_s.to_f / 10_000.0) / 6.0

                  # Plowing 15-03-N -> 15-04-N
                  Ekylibre::FirstRun::Booker.intervene(:plowing, year, 4, 15, 9.78 * coeff, support: support, parameters: { readings: { 'base-plowing-0-1-readstate' => 'plowed' } }) do |i|
                    i.add_cast(reference_name: 'driver',  actor: workers.sample)
                    i.add_cast(reference_name: 'tractor', actor: products[:tractor][:plower].sample)
                    i.add_cast(reference_name: 'plow',    actor: products[:plow].sample)
                    i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
                  end

                  # Sowing 15-04-N -> 30-05-N
                  int = Ekylibre::FirstRun::Booker.intervene(:all_in_one_sowing, year, 5, 2, 6.92 * coeff, range: 15, support: support, parameters: { readings: { 'base-all_in_one_sowing-0-1-readcount' => 80_000 + rand(10_000) } }) do |i|
                    i.add_cast(reference_name: 'seeds',        actor: i.find(Product, variety: :seed, derivative_of: variety.name, can: 'grow'))
                    i.add_cast(reference_name: 'seeds_to_sow', population: (rand(4) + 6) * coeff)

                    i.add_cast(reference_name: 'fertilizer',   actor: products[:fertilizer].sample)
                    i.add_cast(reference_name: 'fertilizer_to_spread', population: (rand(0.2) + 1) * coeff)
                    i.add_cast(reference_name: 'insecticide', actor: products[:insecticide].sample)
                    i.add_cast(reference_name: 'insecticide_to_input', population: (rand(0.2) + 1) * coeff)
                    i.add_cast(reference_name: 'molluscicide', actor: products[:molluscicide].sample)
                    i.add_cast(reference_name: 'molluscicide_to_input', population: (rand(0.2) + 1) * coeff)
                    i.add_cast(reference_name: 'sower',        actor: equipments[:sower].sample)
                    i.add_cast(reference_name: 'driver',       actor: workers.sample)
                    i.add_cast(reference_name: 'tractor',      actor: products[:tractor][:sower].sample)
                    i.add_cast(reference_name: 'land_parcel',  actor: land_parcel)
                    i.add_cast(reference_name: 'cultivation',  variant: ProductNatureVariant.find_or_import!(variety.name).first, population: (area.to_s.to_f / 10_000.0), shape: land_parcel.shape)
                  end

                  # Fertilizing  01-05-M -> 15-06-M
                  Ekylibre::FirstRun::Booker.intervene(:mineral_fertilizing, year, 5, 25, 0.96 * coeff, support: support) do |i|
                    i.add_cast(reference_name: 'fertilizer', actor: products[:fertilizer].sample)
                    i.add_cast(reference_name: 'fertilizer_to_spread', population: 0.4 + coeff * rand(0.6))
                    i.add_cast(reference_name: 'spreader',    actor: products[:spreader].sample)
                    i.add_cast(reference_name: 'driver',      actor: workers.sample)
                    i.add_cast(reference_name: 'tractor',     actor: products[:tractor][:spreader].sample)
                    i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
                  end

                  if w.count.modulo(3).zero?
                    if int
                      cultivation = int.product_parameters.find_by(reference_name: 'cultivation').actor
                      # Treatment herbicide 01-04 30-04
                      Ekylibre::FirstRun::Booker.intervene(:spraying_on_cultivation, year, 5, 27, 1.07 * coeff, support: support) do |i|
                        i.add_cast(reference_name: 'plant_medicine', actor: products[:plant_medicine].sample)
                        i.add_cast(reference_name: 'plant_medicine_to_spray', population: 0.18 + 0.9 * coeff)
                        i.add_cast(reference_name: 'sprayer',  actor: products[:sprayer].sample)
                        i.add_cast(reference_name: 'driver',   actor: workers.sample)
                        i.add_cast(reference_name: 'tractor',  actor: products[:tractor][:catcher].sample)
                        i.add_cast(reference_name: 'cultivation', actor: cultivation)
                      end
                    end
                  end

                  # Hoeing  01-06-M -> 30-07-M
                  Ekylibre::FirstRun::Booker.intervene(:hoeing, year, 6, 20, 3 * coeff, support: support, parameters: { readings: { 'base-hoeing-0-1-readstate' => 'covered' } }) do |i|
                    i.add_cast(reference_name: 'cultivator',  actor: equipments[:hoe].sample)
                    i.add_cast(reference_name: 'driver',      actor: workers.sample)
                    i.add_cast(reference_name: 'tractor',     actor: products[:tractor][:equipment].sample)
                    i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
                  end
                  w.check_point
                end
              end
            end
          end

          count :irrigation_interventions do |w|
            a = Activity.of_families(:maize_crops)
            Production.of_activities(a).where(irrigated: true).joins(:activity, :campaign).find_each do |production|
              next unless production.active?
              year = production.campaign.name.to_i
              Ekylibre::FirstRun::Booker.production = production
              production.supports.joins(:storage, :activity).find_each do |support|
                next unless support.active?
                land_parcel = support.storage
                next unless area = land_parcel.shape_area
                coeff = (area.to_s.to_f / 10_000.0) / 6.0

                if sowing_intervention = support.interventions.of_nature(:sowing).reorder(:started_at).last
                  cultivation = sowing_intervention.product_parameters.find_by(reference_name: 'cultivation').actor
                  # Watering  15-05-M -> 31-08-M
                  Ekylibre::FirstRun::Booker.intervene(:watering, year, 7, 15, 0.96 * coeff, support: support) do |i|
                    i.add_cast(reference_name: 'water',      actor: i.find(Product, variety: :water))
                    i.add_cast(reference_name: 'water_to_spread', population: 200 * coeff)
                    i.add_cast(reference_name: 'spreader',    actor: i.find(Product, can: 'spread(water)'))
                    i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
                    i.add_cast(reference_name: 'cultivation', actor: cultivation)
                  end
                end
                w.check_point
              end
            end
          end

          # interventions for grass
          count :grass_interventions do |w|
            Production.joins(:variant, :activity, :campaign).find_each do |production|
              next unless production.active?
              variety = Nomen::Variety[production.variant.variety]
              next unless variety <= :poa
              year = production.campaign.name.to_i
              Ekylibre::FirstRun::Booker.production = production
              production.supports.joins(:storage, :activity).find_each do |support|
                next unless support.active?
                land_parcel = support.storage
                next unless area = land_parcel.shape_area
                coeff = (area.to_s.to_f / 10_000.0) / 6.0
                bob = nil
                sowing = support.interventions.where(reference_name: 'sowing').where('started_at < ?', Date.civil(year, 6, 6)).order('stopped_at DESC').first
                if cultivation = begin
                                   sowing.product_parameters.find_by(reference_name: 'cultivation').actor
                                 rescue
                                   nil
                                 end
                  int = Ekylibre::FirstRun::Booker.intervene(:plant_mowing, year, 6, 6, 2.8 * coeff, support: support) do |i|
                    bob = i.find(Worker)
                    i.add_cast(reference_name: 'mower_driver', actor: bob)
                    i.add_cast(reference_name: 'tractor',      actor: i.find(Product, can: 'tow(mower)'))
                    i.add_cast(reference_name: 'mower',        actor: i.find(Product, can: 'mow'))
                    i.add_cast(reference_name: 'cultivation',  actor: cultivation)
                    i.add_cast(reference_name: 'straw', population: 1.5 * coeff, variant: ProductNatureVariant.find_or_import!(:straw, derivative_of: cultivation.variety).first)
                  end

                  straw = int.product_parameters.find_by(reference_name: 'straw').actor
                  Ekylibre::FirstRun::Booker.intervene(:straw_bunching, year, 6, 20, 3.13 * coeff, support: support) do |i|
                    i.add_cast(reference_name: 'tractor',        actor: i.find(Product, can: 'tow(baler)'))
                    i.add_cast(reference_name: 'baler_driver',   actor: i.find(bob.others))
                    i.add_cast(reference_name: 'baler',          actor: i.find(Product, can: 'bunch'))
                    i.add_cast(reference_name: 'straw_to_bunch', actor: straw)
                    i.add_cast(reference_name: 'straw_bales', population: 1.5 * coeff, variant: ProductNatureVariant.import_from_nomenclature(cultivation.variety.to_s == 'triticum_durum' ? :hard_wheat_straw_bales : :wheat_straw_bales))
                  end
                end
                w.check_point
              end
            end
          end

          # interventions for cereals
          count :cereals_interventions do |w|
            Production.joins(:variant, :activity, :campaign).find_each do |production|
              next unless production.active?
              variety = Nomen::Variety[production.variant.variety]
              next unless variety <= :triticum_aestivum || variety <= :triticum_durum || variety <= :zea || variety <= :hordeum
              year = production.campaign.name.to_i
              Ekylibre::FirstRun::Booker.production = production
              production.supports.joins(:storage, :activity).find_each do |support|
                next unless support.active?
                land_parcel = support.storage
                next unless area = land_parcel.shape_area
                coeff = (area.to_s.to_f / 10_000.0) / 6.0
                # Harvest 01-07-M 30-07-M
                sowing = support.interventions.where(reference_name: 'sowing').where('started_at < ?', Date.civil(year, 7, 1)).order('stopped_at DESC').first
                if cultivation = begin
                                   sowing.product_parameters.find_by(reference_name: 'cultivation').actor
                                 rescue
                                   nil
                                 end
                  Ekylibre::FirstRun::Booker.intervene(:grains_harvest, year, 7, 1, 3.13 * coeff, support: support) do |i|
                    i.add_cast(reference_name: 'cropper',        actor: i.find(Product, can: 'harvest(poaceae)'))
                    i.add_cast(reference_name: 'cropper_driver', actor: i.find(Worker))
                    i.add_cast(reference_name: 'cultivation',    actor: cultivation)
                    i.add_cast(reference_name: 'grains',         population: 4.2 * coeff, variant: ProductNatureVariant.find_or_import!(:grain, derivative_of: cultivation.variety).first)
                    i.add_cast(reference_name: 'straws',         population: 1.5 * coeff, variant: ProductNatureVariant.find_or_import!(:straw, derivative_of: cultivation.variety).first)
                  end
                end
                w.check_point
              end
            end
          end
          GC.start

          # intervention for animal treatment
          count :animal_treatment_interventions do |w|
            workers = Worker.all
            products = Product.where(variety: 'preparation').can('care(bos)').all
            Production.joins(:variant, :campaign).find_each do |production|
              variety = Nomen::Variety[production.variant.variety]
              next unless variety <= :bos
              year = production.campaign.name.to_i
              Ekylibre::FirstRun::Booker.production = production
              production.supports.joins(:storage).find_each do |support|
                next unless support.storage.is_a?(AnimalGroup)
                support.storage.members_at.find_each do |animal|
                  Ekylibre::FirstRun::Booker.intervene(:animal_treatment, year - 1, 9, 15, 0.5, support: support, parameters: { readings: { 'base-animal_treatment-0-1-readhealth' => 'false' } }) do |i|
                    i.add_cast(reference_name: 'animal',           actor: animal)
                    i.add_cast(reference_name: 'caregiver',        actor: workers.sample)
                    i.add_cast(reference_name: 'animal_medicine',  actor: products.sample)
                    i.add_cast(reference_name: 'animal_medicine_to_give', population: 1 + rand(3))
                  end
                end
                w.check_point
                GC.start
              end
            end
          end

          # intervention for animal insemination
          count :animal_insemination_interventions do |w|
            workers = Worker.can('administer_inseminate(animal)').all
            products = Product.where(variety: :vial).derivative_of(:bos).can('inseminate(animal)').all
            unless workers.any?
              puts 'No workers'.red
              break
            end
            unless products.any?
              puts 'No vials'.red
              break
            end
            Production.joins(:variant, :campaign).find_each do |production|
              variety = Nomen::Variety[production.variant.variety]
              next unless variety <= :bos && production.variant.sex == 'female'
              year = production.campaign.name.to_i
              Ekylibre::FirstRun::Booker.production = production
              production.supports.joins(:storage).find_each do |support|
                next unless support.storage.is_a?(AnimalGroup)
                support.storage.members_at.find_each do |animal|
                  Ekylibre::FirstRun::Booker.intervene(:animal_artificial_insemination, year - 1, 9, 15, 0.5, support: support, parameters: { readings: { 'base-animal_artificial_insemination-0-1-readstate' => 'heat', 'base-animal_artificial_insemination-0-1-readhealth' => 'true', 'base-animal_artificial_insemination-0-1-readembryo' => 'false' } }) do |i|
                    i.add_cast(reference_name: 'animal',       actor: animal)
                    i.add_cast(reference_name: 'inseminator',  actor: workers.sample)
                    i.add_cast(reference_name: 'vial',         actor: products.sample)
                    i.add_cast(reference_name: 'vial_to_give', population: 1)
                  end
                end
                w.check_point
                GC.start
              end
            end
          end

          count :wine_interventions do |w|
            Production.joins(:variant, :campaign).find_each do |production|
              variety = Nomen::Variety[production.variant.variety]
              next unless variety <= :wine
              year = production.campaign.name.to_i
              Ekylibre::FirstRun::Booker.production = production
              production.supports.joins(:storage).find_each do |support|
                next unless support.storage.contents.count > 0
                Ekylibre::FirstRun::Booker.intervene(:complete_wine_transfer, year - 1, 9, 15, 0.5, support: support) do |i|
                  i.add_cast(reference_name: 'tank',             actor: support.storage)
                  i.add_cast(reference_name: 'wine',             actor: support.storage.contents.first)
                  i.add_cast(reference_name: 'wine_man',         actor: i.find(Worker))
                  i.add_cast(reference_name: 'destination_tank', actor: i.find(Equipment, can: "store(wine)', 'store_liquid"))
                end
              end
              w.check_point
            end
          end
        end
      end
    end
  end
end
