# -*- coding: utf-8 -*-
load_data :animals do |loader|

  # import variant for creating animal
  cow_vl     = ProductNatureVariant.import_from_nomenclature(:female_adult_cow)
  cow_trepro = ProductNatureVariant.import_from_nomenclature(:male_adult_cow)
  cow_gen    = ProductNatureVariant.import_from_nomenclature(:female_young_cow)
  cow_taur   = ProductNatureVariant.import_from_nomenclature(:male_young_cow)
  cow_v      = ProductNatureVariant.import_from_nomenclature(:calf)
  herd       = ProductNatureVariant.import_from_nomenclature(:cattle_herd)

  # find place for creating animal
  place_v = BuildingDivision.find_by_work_number("B09_D1")
  place_gen = BuildingDivision.find_by_work_number("B03_D9")
  place_taur = BuildingDivision.find_by_work_number("B04_D4")
  place_vl = BuildingDivision.find_by_work_number("B07_D2")

  # add animals credentials in preferences
  synel_login = Preference.where(:nature => :string, :name => "services.synel17.login", :string_value => "17387001").first_or_create
  cattling_number = Preference.where(:nature => :string, :name => "entity_identification.ede.cattling_number", :string_value => "FR17387001").first_or_create
  owner_number = Preference.where(:nature => :string, :name => "entity_identification.ede.owner_number", :string_value => "FR01700006989").first_or_create


  loader.count :animal_natures do |w|
    #############################################################################
    for group in [{:name => "Vaches Laitières", :work_number => "VL", :default_storage => place_vl},
                  {:name => "Génisses 3",  :work_number => "GEN_3", :default_storage => place_gen},
                  {:name => "Génisses 2",  :work_number => "GEN_2", :default_storage => place_gen},
                  {:name => "Génisses 1",  :work_number => "GEN_1", :default_storage => place_gen},
                  {:name => "Veaux Niche", :work_number => "VEAU", :description => "Veaux en niche individuel", :default_storage => place_v},
                  {:name => "Veaux 8-15j", :work_number => "VEAU_8_15", :description => "Veaux vendus à 8-15 J", :default_storage => place_v},
                  {:name => "Taurillons", :work_number => "TAUR", :description => "Taurillons vendus entre 21 et 26 mois", :default_storage => place_taur}
                 ]
      unless AnimalGroup.find_by_work_number(group[:work_number])
        AnimalGroup.create!({ :variant_id => herd.id}.merge(group))
      end
      w.check_point
    end
  end

  # find groupe for creating animal
  group_v = AnimalGroup.find_by_work_number("VEAU")
  group_gen1 = AnimalGroup.find_by_work_number("GEN_1")
  group_gen2 = AnimalGroup.find_by_work_number("GEN_2")
  group_gen3 = AnimalGroup.find_by_work_number("GEN_3")
  group_taur = AnimalGroup.find_by_work_number("TAUR")
  group_vl = AnimalGroup.find_by_work_number("VL")



  file = loader.path("animals-synel17.csv")
  if file.exist?

    loader.count :synel_animal_import do |w|
      #############################################################################

      initial_arrival_causes = {"N" => :birth, "A" => :purchase, "P" => :housing, "" => :other }
      arrival_causes = {"N" => :interior, "A" => :exterior, "P" => :exterior, "" => :interior }
      departure_causes = {"M" => :exterior, "B" => :exterior, "" => :exterior, "C" => :interior , "E" => :exterior}


      pictures = Dir.glob(loader.path("animals-ld", "*.jpg"))
      photo_taur = loader.path("animals", "taurillon.jpg")
      photo_v = loader.path("animals", "veau.jpg")
      CSV.foreach(file, :encoding => "CP1252", :col_sep => ";", :headers => true) do |row|
        next if row[4].blank?
        r = OpenStruct.new(:country => row[0],
                           :identification_number => row[1],
                           :work_number => row[2],
                           :name => (row[3].blank? ? Faker::Name.first_name+"(MN)" : row[3].capitalize),
                           :born_on => (row[4].blank? ? nil : Date.civil(*row[4].to_s.split(/\//).reverse.map(&:to_i))),
                           :corabo => row[5],
                           :sex => (row[6] == "F" ? :female : :male),
                           :arrival_cause => (arrival_causes[row[7]] || row[7]),
                           :initial_arrival_cause => (initial_arrival_causes[row[7]] || row[7]),
                           :arrived_on => (row[8].blank? ? nil : Date.civil(*row[8].to_s.split(/\//).reverse.map(&:to_i))),
                           :departure_cause => (departure_causes[row[9]] ||row[9]),
                           :departed_on => (row[10].blank? ? nil : Date.civil(*row[10].to_s.split(/\//).reverse.map(&:to_i)))
                           )


        # case = VEAU
        if r.born_on > (Date.today - 3.months) and r.born_on < (Date.today)
          f = File.open(photo_v)
          animal = Animal.create!(:variant_id => cow_v.id, :name => r.name, :variety => "bos", :identification_number => r.identification_number,
                                  :work_number => r.work_number, :born_at => r.born_on, :dead_at => r.departed_on,
                                  :picture => f, :initial_owner => Entity.of_company, :initial_arrival_cause => r.initial_arrival_cause, :initial_container => place_v, :default_storage => place_v
                                  )
          f.close
          # set default indicators
          animal.is_measured!(:sex, r.sex, at: r.born_on.to_datetime)
          animal.is_measured!(:net_mass, 55.45.in_kilogram, at: r.born_on.to_datetime)
          animal.is_measured!(:net_mass, 75.89.in_kilogram, at: (r.born_on.to_datetime + 2.months))
          animal.is_measured!(:healthy, true)
          animal.is_measured!(:healthy, false, at: (Time.now - 2.days))
          animal.is_measured!(:healthy, true, at: (Time.now - 3.days))
          # place the current animal in the default group with born_at
          if place_v and group_v
            ProductLocalization.create!(:container_id => place_v.id, :product_id => animal.id, :nature => r.arrival_cause, :started_at => r.arrived_on, :stopped_at => r.departed_on)
            # add animal in group
            group_v.add(animal, r.arrived_on)
            # remove animal from group if r.departed_on
            group_v.remove(animal, r.departed_on) if r.departed_on
          end

          # case = GENISSE 1
        elsif r.born_on > (Date.today - 12.months) and r.born_on < (Date.today - 3.months) and r.sex == :female
          f = File.open(pictures.sample)
          animal = Animal.create!(:variant_id => cow_gen.id, :name => r.name, :variety => "bos",
                                  :identification_number => r.identification_number, :work_number => r.work_number,
                                  :born_at => r.born_on, :dead_at => r.departed_on,
                                  :picture => f, :initial_owner => Entity.of_company, :initial_arrival_cause => r.initial_arrival_cause, :initial_container => place_gen, :default_storage => place_gen
                                  )
          f.close
          # set default indicators
          animal.is_measured!(:net_mass, 55.45.in_kilogram, at: r.born_on.to_datetime)
          animal.is_measured!(:net_mass, 75.89.in_kilogram, at: (r.born_on.to_datetime + 2.months))
          animal.is_measured!(:net_mass, 89.56.in_kilogram, at: (r.born_on.to_datetime + 4.months))
          animal.is_measured!(:net_mass, 129.56.in_kilogram, at: (r.born_on.to_datetime + 8.months))
          animal.is_measured!(:healthy, true)
          animal.is_measured!(:healthy, false, at: (Time.now - 2.days))
          animal.is_measured!(:healthy, true, at: (Time.now - 3.days))
          if place_gen and group_gen1
            # place the current animal in the default group with born_at
            ProductLocalization.create!(:container_id => place_gen.id, :product_id => animal.id, :nature => r.arrival_cause, :started_at => r.arrived_on, :stopped_at => r.departed_on)
            # add animal in group
            group_gen1.add(animal, r.arrived_on)
            # remove animal from group if r.departed_on
            group_gen1.remove(animal, r.departed_on) if r.departed_on
          end

          # case = GENISSE 3
        elsif r.born_on > (Date.today - 28.months) and r.born_on < (Date.today - 12.months) and r.sex == :female
          f = File.open(pictures.sample)
          animal = Animal.create!(:variant_id => cow_gen.id, :name => r.name, :variety => "bos",
                                  :identification_number => r.identification_number, :work_number => r.work_number,
                                  :born_at => r.born_on, :dead_at => r.departed_on,
                                  :picture => f, :initial_owner => Entity.of_company, :initial_arrival_cause => r.initial_arrival_cause, :initial_container => place_gen, :default_storage => place_gen
                                  )
          f.close
          # set default indicators
          animal.is_measured!(:net_mass, 55.45.in_kilogram, at: r.born_on.to_datetime)
          animal.is_measured!(:net_mass, 75.89.in_kilogram, at: (r.born_on.to_datetime + 2.months))
          animal.is_measured!(:net_mass, 89.56.in_kilogram, at: (r.born_on.to_datetime + 4.months))
          animal.is_measured!(:net_mass, 129.56.in_kilogram, at: (r.born_on.to_datetime + 8.months))
          animal.is_measured!(:net_mass, 189.56.in_kilogram, at: (r.born_on.to_datetime + 12.months))
          animal.is_measured!(:healthy, true)
          animal.is_measured!(:healthy, false, at: (Time.now - 2.days))
          animal.is_measured!(:healthy, true, at: (Time.now - 3.days))
          if place_gen and group_gen3
            # place the current animal in the default group with born_at
            ProductLocalization.create!(:container_id => place_gen.id, :product_id => animal.id, :nature => r.arrival_cause, :started_at => r.arrived_on, :stopped_at => r.departed_on)
            # add animal in group
            group_gen3.add(animal, r.arrived_on)
            # remove animal from group if r.departed_on
            group_gen3.remove(animal, r.departed_on) if r.departed_on
          end

          # case = VL
        elsif r.born_on > (Date.today - 20.years) and r.born_on < (Date.today - 28.months) and r.sex == :female
          f = File.open(pictures.sample)
          animal = Animal.create!(:variant_id => cow_vl.id, :name => r.name, :variety => "bos",
                                  :identification_number => r.identification_number, :work_number => r.work_number,
                                  :born_at => r.born_on, :dead_at => r.departed_on,
                                  :picture => f, :initial_owner => Entity.of_company, :initial_arrival_cause => r.initial_arrival_cause, :initial_container => place_vl, :default_storage => place_vl
                                  )
          f.close
          # set default indicators
          animal.is_measured!(:net_mass, 55.45.in_kilogram, at: r.born_on.to_datetime)
          animal.is_measured!(:net_mass, 75.89.in_kilogram, at: (r.born_on.to_datetime + 2.months))
          animal.is_measured!(:net_mass, 89.56.in_kilogram, at: (r.born_on.to_datetime + 4.months))
          animal.is_measured!(:net_mass, 129.56.in_kilogram, at: (r.born_on.to_datetime + 8.months))
          animal.is_measured!(:net_mass, 189.56.in_kilogram, at: (r.born_on.to_datetime + 12.months))
          animal.is_measured!(:net_mass, 389.56.in_kilogram, at: (r.born_on.to_datetime + 24.months))
          animal.is_measured!(:healthy, true)
          animal.is_measured!(:healthy, false, at: (Time.now - 2.days))
          animal.is_measured!(:healthy, true, at: (Time.now - 3.days))
          if place_vl and group_vl
            # place the current animal in the default group with born_at
            ProductLocalization.create!(:container_id => place_vl.id, :product_id => animal.id, :nature => r.arrival_cause, :started_at => r.arrived_on, :stopped_at => r.departed_on)
            # add animal in group
            group_vl.add(animal, r.arrived_on)
            # remove animal from group if r.departed_on
            group_vl.remove(animal, r.departed_on) if r.departed_on
          end

          # case = TAURILLON
        elsif r.born_on > (Date.today - 10.years) and r.born_on < (Date.today - 3.months) and r.sex == :male
          f = File.open(photo_taur)
          animal = Animal.create!(:variant_id => cow_taur.id, :name => r.name, :variety => "bos",
                                  :identification_number => r.identification_number, :work_number => r.work_number,
                                  :born_at => r.born_on, :dead_at => r.departed_on,
                                  :picture => f, :initial_owner => Entity.of_company, :initial_arrival_cause => r.initial_arrival_cause, :initial_container => place_taur, :default_storage => place_taur
                                  )
          f.close
          # set default indicators
          animal.is_measured!(:net_mass, 55.45.in_kilogram, at: r.born_on.to_datetime)
          animal.is_measured!(:net_mass, 75.89.in_kilogram, at: (r.born_on.to_datetime + 2.months))
          animal.is_measured!(:net_mass, 89.56.in_kilogram, at: (r.born_on.to_datetime + 4.months))
          animal.is_measured!(:net_mass, 129.56.in_kilogram, at: (r.born_on.to_datetime + 8.months))
          animal.is_measured!(:net_mass, 189.56.in_kilogram, at: (r.born_on.to_datetime + 12.months))
          animal.is_measured!(:net_mass, 389.56.in_kilogram, at: (r.born_on.to_datetime + 24.months))
          animal.is_measured!(:healthy, true)
          animal.is_measured!(:healthy, false, at: (Time.now - 2.days))
          animal.is_measured!(:healthy, true, at: (Time.now - 3.days))
          if place_taur and group_taur
            # place the current animal in the default group with born_at
            ProductLocalization.create!(:container_id => place_taur.id, :product_id => animal.id, :nature => r.arrival_cause, :started_at => r.arrived_on, :stopped_at => r.departed_on)
            # add animal in group
            group_taur.add(animal, r.arrived_on)
            # remove animal from group if r.departed_on
            group_taur.remove(animal, r.departed_on) if r.departed_on
          end

        end
        w.check_point

      end
    end
  end

  file = loader.path("liste_males_reproducteurs_race_normande_ISU_130.txt")
  if file.exist?
    loader.count :upra_reproductor_list_import do |w|
      picture_trepro = loader.path("animals", "taurillon.jpg")
      now = Time.now - 2.months
      CSV.foreach(file, :encoding => "CP1252", :col_sep => "\t", :headers => true) do |row|
        next if row[4].blank?
        r = OpenStruct.new(:order => row[0],
                           :name => row[1],
                           :identification_number => row[2],
                           :father => row[3],
                           :provider => row[4],
                           :isu => row[5].to_i,
                           :inel => row[9].to_i,
                           :tp => row[10].to_f,
                           :tb => row[11].to_f
                           )
        # case = TAUREAU REPRO
        animal = Animal.create!(:variant_id => cow_trepro.id, :name => r.name, :variety => "bos", :identification_number => r.identification_number[-10..-1], :initial_owner => Entity.where(:of_company => false).all.sample, :initial_arrival_cause => :other)
        # set default indicators
        animal.is_measured!(:unique_synthesis_index,  r.isu.in_unity,  at: now)
        animal.is_measured!(:economical_milk_index, r.inel.in_unity, at: now)
        animal.is_measured!(:protein_concentration_index,   r.tp.in_unity,   at: now)
        animal.is_measured!(:fat_matter_concentration_index,   r.tb.in_unity,   at: now)
        # put in an external localization
        ProductLocalization.create!(:nature => :exterior, :product_id => animal.id)
        w.check_point

      end
    end
  end


  file = loader.path("animals-synel17_inventory.csv")
  if file.exist?
    loader.count :assign_parents_with_inventory do |w|

      CSV.foreach(file, :encoding => "CP1252", :col_sep => ",", :headers => true) do |row|
        next if row[4].blank?
        r = OpenStruct.new(:identification_number => row[3],
                           :name => (row[4].blank? ? Faker::Name.first_name+"(MN)" : row[4].capitalize),
                           :mother_identification_number => row[13],
                           :mother_name => (row[14].blank? ? Faker::Name.first_name : row[14].capitalize),
                           :father_identification_number => row[16],
                           :father_name => (row[17].blank? ? Faker::Name.first_name : row[17].capitalize)
                           )
        # check if animal is present in DB
        if animal = Animal.find_by_identification_number(r.identification_number)
          # check if animal mother is present in DB or create it
          if animal_mother = Animal.find_by_identification_number(r.mother_identification_number)
            animal.mother = animal_mother
          else
            unless r.mother_identification_number.blank?
              # case = VL
              animal_mother = Animal.create!(:variant_id => cow_vl.id, :name => r.mother_name, :variety => "bos",
                                             :identification_number => r.mother_identification_number, :work_number => r.mother_identification_number[-4..-1], :initial_owner => Entity.of_company, :initial_arrival_cause => :birth, :initial_container => place_vl, :default_storage => place_vl )

              # set default indicators
              animal_mother.is_measured!(:healthy, true)
              animal_mother.is_measured!(:healthy, false, at: (Time.now - 2.days))
              animal_mother.is_measured!(:healthy, true, at: (Time.now - 3.days))
              animal.mother = animal_mother
            end
          end
          if animal_father = Animal.find_by_identification_number(r.father_identification_number)
            animal.father = animal_father
          else
            unless r.father_identification_number.blank?
              # case = TAUREAU REPRO
              animal_father = Animal.create!(:variant_id => cow_trepro.id, :name => r.father_name, :variety => "bos", :identification_number => r.father_identification_number, :initial_owner => Entity.where(:of_company => false).all.sample, :initial_arrival_cause => :other)
              # set default indicators
              animal.father = animal_father
            end
          end
          animal.save!
          w.check_point
        end
      end
    end
  end

end
