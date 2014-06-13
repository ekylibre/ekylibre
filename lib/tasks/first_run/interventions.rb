# -*- coding: utf-8 -*-
load_data :interventions do |loader|

  # interventions for all poaceae
  sowables = [:poa, :hordeum_hibernum, :secale, :triticosecale, :triticum, :brassica_napus, :pisum_hibernum].collect do |n|
    Nomen::Varieties[n]
  end
  
  spring_sowables = [:zea, :hordeum_vernum, :pisum_vernum].collect do |n|
    Nomen::Varieties[n]
  end

  if loader.manifest[:demo]

    loader.count :cultural_interventions do |w|
      for production in Production.all
        if production.active?
          variety = production.variant.variety
          if (Nomen::Varieties[variety].self_and_parents & sowables).any?
            year = production.campaign.name.to_i
            Ekylibre::FirstRun::Booker.production = production
            for support in production.supports
              if support.active?
                land_parcel = support.storage
                if area = land_parcel.shape_area
                  coeff = (area.to_s.to_f / 10000.0) / 6.0
                  # 7.99 -> 20.11 -> 40.21

                  # Plowing 15-09-N -> 15-10-N
                  Ekylibre::FirstRun::Booker.intervene(:plowing, year - 1, 9, 15, 9.78 * coeff, support: support, parameters: {readings: {"base-plowing-0-500-1" => "plowed"}}) do |i|
                    i.add_cast(reference_name: 'driver',  actor: i.find(Worker))
                    i.add_cast(reference_name: 'tractor', actor: i.find(Product, can: "tow(plower)"))
                    i.add_cast(reference_name: 'plow',    actor: i.find(Product, can: "plow"))
                    i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
                  end

                  # Sowing 15-10-N -> 30-10-N
                  int = Ekylibre::FirstRun::Booker.intervene(:sowing, year - 1, 10, 15, 6.92 * coeff, range: 15, support: support, parameters: {readings: {"base-sowing-0-750-2" => 2000000 + rand(250000)}}) do |i|
                    i.add_cast(reference_name: 'seeds',        actor: i.find(Product, variety: :seed, derivative_of: variety, can: "grow"))
                    i.add_cast(reference_name: 'seeds_to_sow', population: rand(5) + 1)
                    i.add_cast(reference_name: 'sower',        actor: i.find(Product, can: "sow"))
                    i.add_cast(reference_name: 'driver',       actor: i.find(Worker))
                    i.add_cast(reference_name: 'tractor',      actor: i.find(Product, can: "tow(sower)"))
                    i.add_cast(reference_name: 'land_parcel',  actor: land_parcel)
                    i.add_cast(reference_name: 'cultivation',  variant: ProductNatureVariant.find_or_import!(variety).first, population: (area.to_s.to_f / 10000.0), shape: land_parcel.shape)
                  end

                  cultivation = int.casts.find_by(reference_name: 'cultivation').actor

                  # Fertilizing  01-03-M -> 31-03-M
                  Ekylibre::FirstRun::Booker.intervene(:mineral_fertilizing, year, 3, 1, 0.96 * coeff, support: support) do |i|
                    i.add_cast(reference_name: 'fertilizer',  actor: i.find(Product, variety: :preparation, can: "fertilize"))
                    i.add_cast(reference_name: 'fertilizer_to_spread', population: 0.4 + coeff * rand(0.6))
                    i.add_cast(reference_name: 'spreader',    actor: i.find(Product, can: "spread(preparation)"))
                    i.add_cast(reference_name: 'driver',      actor: i.find(Worker))
                    i.add_cast(reference_name: 'tractor',     actor: i.find(Product, can: "tow(spreader)"))
                    i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
                  end

                  # Organic Fertilizing  01-03-M -> 31-03-M
                  Ekylibre::FirstRun::Booker.intervene(:organic_fertilizing, year, 3, 1, 0.96 * coeff, support: support) do |i|
                    i.add_cast(reference_name: 'manure',      actor: i.find(Product, variety: :excrement, can: "fertilize"))
                    i.add_cast(reference_name: 'manure_to_spread', population: 0.2 + 4 * coeff)
                    i.add_cast(reference_name: 'spreader',    actor: i.find(Product, can: "spread(preparation)"))
                    i.add_cast(reference_name: 'driver',      actor: i.find(Worker))
                    i.add_cast(reference_name: 'tractor',     actor: i.find(Product, can: "tow(spreader)"))
                    i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
                  end

                  if w.count.modulo(3).zero? # AND NOT prairie
                    # Treatment herbicide 01-04 30-04
                    Ekylibre::FirstRun::Booker.intervene(:spraying_on_cultivation, year, 4, 1, 1.07 * coeff, support: support) do |i|
                      i.add_cast(reference_name: 'plant_medicine', actor: i.find(Product, variety: :preparation, can: "care(plant)"))
                      i.add_cast(reference_name: 'plant_medicine_to_spray', population: 0.18 + 0.9 * coeff)
                      i.add_cast(reference_name: 'sprayer',  actor: i.find(Product, can: "spray"))
                      i.add_cast(reference_name: 'driver',   actor: i.find(Worker))
                      i.add_cast(reference_name: 'tractor',  actor: i.find(Product, can: "catch"))
                      i.add_cast(reference_name: 'cultivation', actor: cultivation)
                    end
                  end

                end
              end
              w.check_point
            end
          end
        end
      end
    end

  loader.count :irrigation_interventions do |w|
      for production in Production.all
        if production.active?
          variety = production.variant.variety
            year = production.campaign.name.to_i
            Ekylibre::FirstRun::Booker.production = production
            for support in production.supports
              # for active and irrigated support only
              if support.active? and support.irrigated?
                land_parcel = support.storage
                if area = land_parcel.shape_area
                  coeff = (area.to_s.to_f / 10000.0) / 6.0
                  
                  if sowing_intervention = support.interventions.of_nature(:sowing).reorder(:started_at).last
                    
                    cultivation = sowing_intervention.casts.find_by(reference_name: 'cultivation').actor
                    
                    # Watering  01-05-M -> 31-08-M
                    Ekylibre::FirstRun::Booker.intervene(:watering, year, 5, 15, 0.96 * coeff, support: support) do |i|
                      i.add_cast(reference_name: 'water',      actor: i.find(Product, variety: :water))
                      i.add_cast(reference_name: 'water_to_spread', population: 2 * coeff)
                      i.add_cast(reference_name: 'spreader',    actor: i.find(Product, can: "spread(water)"))
                      i.add_cast(reference_name: 'driver',      actor: i.find(Worker))
                      i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
                      i.add_cast(reference_name: 'cultivation', actor: cultivation)
                    end
                  end
                
                end
              end
              w.check_point
            end
        end
      end
    end

    # interventions for grass
    loader.count :grass_interventions do |w|
      for production in Production.all
        if production.active?
          variety = production.variant.variety
          if Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:poa])
            year = production.campaign.name.to_i
            Ekylibre::FirstRun::Booker.production = production
            for support in production.supports
              if support.active?
                land_parcel = support.storage
                if area = land_parcel.shape_area
                  coeff = (area.to_s.to_f / 10000.0) / 6.0

                  bob = nil
                  sowing = support.interventions.where(reference_name: "sowing").where("started_at < ?", Date.civil(year, 6, 6)).order("stopped_at DESC").first
                  if cultivation = sowing.casts.find_by(reference_name: 'cultivation').actor rescue nil
                    int = Ekylibre::FirstRun::Booker.intervene(:plant_mowing, year, 6, 6, 2.8 * coeff, support: support) do |i|
                      bob = i.find(Worker)
                      i.add_cast(reference_name: 'mower_driver', actor: bob)
                      i.add_cast(reference_name: 'tractor',      actor: i.find(Product, can: "tow(mower)"))
                      i.add_cast(reference_name: 'mower',        actor: i.find(Product, can: "mow"))
                      i.add_cast(reference_name: 'cultivation',  actor: cultivation)
                      i.add_cast(reference_name: 'straw', population: 1.5 * coeff, variant: ProductNatureVariant.find_or_import!(:straw, derivative_of: cultivation.variety).first)
                    end

                    straw = int.casts.find_by_reference_name('straw').actor
                    Ekylibre::FirstRun::Booker.intervene(:straw_bunching, year, 6, 20, 3.13 * coeff, support: support) do |i|
                      i.add_cast(reference_name: 'tractor',        actor: i.find(Product, can: "tow(baler)"))
                      i.add_cast(reference_name: 'baler_driver',   actor: i.find(bob.others))
                      i.add_cast(reference_name: 'baler',          actor: i.find(Product, can: "bunch"))
                      i.add_cast(reference_name: 'straw_to_bunch', actor: straw)
                      i.add_cast(reference_name: 'straw_bales', population: 1.5 * coeff, variant: ProductNatureVariant.import_from_nomenclature(cultivation.variety.to_s == 'triticum_durum' ? :hard_wheat_straw_bales : :wheat_straw_bales))
                    end
                  end
                end
              end
              w.check_point
            end
          end
        end
      end
    end

    # interventions for cereals
    loader.count :cereals_interventions do |w|
      for production in Production.all
        if production.active?
          variety = production.variant.variety
          if Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:triticum_aestivum]) || Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:triticum_durum]) || Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:zea]) || Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:hordeum])
            year = production.campaign.name.to_i
            Ekylibre::FirstRun::Booker.production = production
            for support in production.supports
              if support.active?
                land_parcel = support.storage
                if area = land_parcel.shape_area
                  coeff = (area.to_s.to_f / 10000.0) / 6.0
                  # Harvest 01-07-M 30-07-M
                  sowing = support.interventions.where(reference_name: "sowing").where("started_at < ?", Date.civil(year, 7, 1)).order("stopped_at DESC").first
                  if cultivation = sowing.casts.find_by(reference_name: 'cultivation').actor rescue nil
                    Ekylibre::FirstRun::Booker.intervene(:grains_harvest, year, 7, 1, 3.13 * coeff, support: support) do |i|
                      i.add_cast(reference_name: 'cropper',        actor: i.find(Product, can: "harvest(poaceae)"))
                      i.add_cast(reference_name: 'cropper_driver', actor: i.find(Worker))
                      i.add_cast(reference_name: 'cultivation',    actor: cultivation)
                      i.add_cast(reference_name: 'grains',         population: 4.2 * coeff, variant: ProductNatureVariant.find_or_import!(:grain, derivative_of: cultivation.variety).first)
                      i.add_cast(reference_name: 'straws',         population: 1.5 * coeff, variant: ProductNatureVariant.find_or_import!(:straw, derivative_of: cultivation.variety).first)
                    end
                  end
                end
              end
              w.check_point
            end
          end
        end
      end
    end

    loader.count :animal_interventions do |w|
      for production in Production.all
        variety = production.variant.variety
        if Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:bos])
          year = production.campaign.name.to_i
          Ekylibre::FirstRun::Booker.production = production
          for support in production.supports
            if support.storage.is_a?(AnimalGroup)
              for animal in support.storage.members_at()
                Ekylibre::FirstRun::Booker.intervene(:animal_treatment, year - 1, 9, 15, 0.5, support: support, parameters: {readings: {"base-animal_treatment-0-100-1" => "false"}}) do |i|
                  i.add_cast(reference_name: 'animal',           actor: animal)
                  i.add_cast(reference_name: 'caregiver',        actor: i.find(Worker))
                  i.add_cast(reference_name: 'animal_medicine',         actor: i.find(Product, variety: :preparation, can: "care(bos)"))
                  i.add_cast(reference_name: 'animal_medicine_to_give', population: 1 + rand(3))
                end
              end
              w.check_point
            end
          end
        end
      end
    end

    loader.count :wine_interventions do |w|
      for production in Production.all
        variety = production.variant.variety
        if Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:wine])
          year = production.campaign.name.to_i
          Ekylibre::FirstRun::Booker.production = production
          for support in production.supports
            if support.storage.contents.count > 0
              Ekylibre::FirstRun::Booker.intervene(:complete_wine_transfer, year - 1, 9, 15, 0.5, support: support ) do |i|
                i.add_cast(reference_name: 'tank',             actor: support.storage)
                i.add_cast(reference_name: 'wine',             actor: support.storage.contents.first)
                i.add_cast(reference_name: 'wine_man',         actor: i.find(Worker))
                i.add_cast(reference_name: 'destination_tank', actor: i.find(Equipment, can: "store(wine)", can: "store_liquid"))
              end
            end
            w.check_point
          end
        end
      end
    end

    file = loader.path("documents", "prescription_1.jpg")
    if file.exist?
      loader.count :animal_prescriptions do |w|

        # import veterinary prescription in PDF
        document = Document.create!(key: "2100000303_prescription_001", name: "prescription-2100000303", nature: "prescription")
        File.open(file, "rb:ASCII-8BIT") do |f|
          document.archive(f.read, :jpg)
        end

        # create a veterinary
        veterinary = Person.create!(
                                    :first_name => "Veto",
                                    :last_name => "PONTO",
                                    :nature => :person,
                                    :client => false,
                                    :supplier => false
                                    )

        # create veterinary prescription with PDF and veterinary
        prescription = Prescription.create!(prescriptor: veterinary, document: document, reference_number: "2100000303")

        # create an issue for all interventions on animals and update them with prescription and recommender
        for intervention in Intervention.of_nature(:animal_illness_treatment)
          # create an issue
          animal = intervention.casts.of_role(:'animal_illness_treatment-target').first.actor
          started_at = (intervention.started_at - 1.day) || Time.now
          nature = [:mammite, :edema, :limping, :fever, :cough, :diarrhea].sample
          issue = Issue.create!(target_type: animal.class.name, target_id: animal.id, priority: 3, observed_at: started_at, name: Nomen::IssueNatures[nature].human_name, nature: nature, state: ["opened", "closed", "aborted"].sample)
          # add prescription on intervention
          intervention.issue = issue
          intervention.prescription = prescription
          intervention.recommended = true
          intervention.recommender = veterinary
          intervention.save!
          w.check_point
        end
      end

    end
  end

end
