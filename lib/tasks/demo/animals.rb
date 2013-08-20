# -*- coding: utf-8 -*-

demo :animals do

  cow_vl     = ProductNature.import_from_nomenclature(:female_adult_cow).default_variant
  cow_trepro = ProductNature.import_from_nomenclature(:male_adult_cow).default_variant
  cow_gen    = ProductNature.import_from_nomenclature(:female_young_cow).default_variant
  cow_taur   = ProductNature.import_from_nomenclature(:male_young_cow).default_variant
  cow_v      = ProductNature.import_from_nomenclature(:calf).default_variant
  herd       = ProductNature.import_from_nomenclature(:cattle_herd).default_variant

  Ekylibre::fixturize :animal_natures do |w|
    #############################################################################
    # add default product_nature for animals



    for group in [{:name => "Vaches Laitières", :work_number => "VL"},
                  {:name => "Génisses 3",  :work_number => "GEN_3"},
                  {:name => "Génisses 2",  :work_number => "GEN_2"},
                  {:name => "Génisses 1",  :work_number => "GEN_1"},
                  {:name => "Veaux Niche", :work_number => "VEAU_NICHE", :description => "Veaux en niche individuel"},
                  {:name => "Veaux Poulailler 1", :work_number => "VEAU_1"},
                  {:name => "Veaux Poulailler 2", :work_number => "VEAU_2"},
                  {:name => "Taurillons case 7", :work_number => "TAUR_7", :description => "Côté Hangar"},
                  {:name => "Taurillons case 6", :work_number => "TAUR_6"},
                  {:name => "Taurillons case 5", :work_number => "TAUR_5"},
                  {:name => "Taurillons case 4", :work_number => "TAUR_4"},
                  {:name => "Taurillons case 3", :work_number => "TAUR_3"},
                  {:name => "Taurillons case 2", :work_number => "TAUR_2"},
                  {:name => "Taurillons case 1", :work_number => "TAUR_1"}
                 ]
      unless AnimalGroup.find_by_work_number(group[:work_number])
        AnimalGroup.create!({:active => true, :variant_id => herd.id}.merge(group))
      end
      w.check_point
    end
  end

  Ekylibre::fixturize :synel_animal_import do |w|
    #############################################################################
    # set finder for creating animal
    place_v = BuildingDivision.find_by_work_number("B09_D1")
    group_v = AnimalGroup.find_by_work_number("VEAU_1")
    place_gen = BuildingDivision.find_by_work_number("B03_D9")
    group_gen1 = AnimalGroup.find_by_work_number("GEN_1")
    group_gen2 = AnimalGroup.find_by_work_number("GEN_2")
    group_gen3 = AnimalGroup.find_by_work_number("GEN_3")
    place_taur = BuildingDivision.find_by_work_number("B04_D4")
    group_taur = AnimalGroup.find_by_work_number("TAUR_7")
    place_vl = BuildingDivision.find_by_work_number("B07_D2")
    group_vl = AnimalGroup.find_by_work_number("VL")

    arrival_causes = {"N" => :birth, "A" => :purchase, "P" => :housing, "" => :other }
    departure_causes = {"M" => :death, "B" => :sale, "" => :other, "C" => :consumption , "E" => :sale}


    file = Rails.root.join("test", "fixtures", "files", "animals-synel17.csv")
    pictures = Dir.glob(Rails.root.join("test", "fixtures", "files", "animals-ld", "*.jpg"))
    photo_taur = Rails.root.join("test", "fixtures", "files", "animals", "taurillon.jpg")
    photo_v = Rails.root.join("test", "fixtures", "files", "animals", "veau.jpg")
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
                         :arrived_on => (row[8].blank? ? nil : Date.civil(*row[8].to_s.split(/\//).reverse.map(&:to_i))),
                         :departure_cause => (departure_causes[row[9]] ||row[9]),
                         :departed_on => (row[10].blank? ? nil : Date.civil(*row[10].to_s.split(/\//).reverse.map(&:to_i)))
                         )


      # case = VEAU
      if r.born_on > (Date.today - 3.months) and r.born_on < (Date.today)
        f = File.open(photo_v)
        animal = Animal.create!(:variant_id => cow_v.id, :name => r.name, :variety => "bos", :identification_number => r.identification_number,
                                :work_number => r.work_number, :born_at => r.born_on, :dead_at => r.departed_on,
                                :picture => f, :owner_id => Entity.of_company.id
                                )
        f.close
        # set default indicators
        animal.is_measured!(:sex, r.sex)
        animal.is_measured!(:reproductor, false)
        animal.is_measured!(:net_weight, 55.45.in_kilogram, :at => r.born_on.to_datetime)
        animal.is_measured!(:net_weight, 75.89.in_kilogram, :at => (r.born_on.to_datetime + 2.months))
        animal.is_measured!(:animal_disease_state, :healthy)
        animal.is_measured!(:animal_disease_state, :sick, :at => (Time.now - 2.days))
        animal.is_measured!(:animal_disease_state, :healthy, :at => (Time.now - 3.days))
        # place the current animal in the default group with born_at
        if place_v and group_vlib/aggeratio.rb
          ProductLocalization.create!(:container_id => place_v.id, :product_id => animal.id, :nature => :interior, :started_at => r.arrived_on, :stopped_at => r.departed_on, :arrival_cause => r.arrival_cause, :departure_cause => r.departure_cause)
          ProductMembership.create!(:member_id => animal.id, :group_id => group_v.id, :started_at => r.arrived_on, :stopped_at => r.departed_on )
        end

        # case = GENISSE 1
      elsif r.born_on > (Date.today - 12.months) and r.born_on < (Date.today - 3.months) and r.sex == :female
        f = File.open(pictures.sample)
        animal = Animal.create!(:variant_id => cow_v.id, :name => r.name, :variety => "bos",
                                :identification_number => r.identification_number, :work_number => r.work_number,
                                :born_at => r.born_on, :dead_at => r.departed_on,
                                :picture => f, :owner_id => Entity.of_company.id
                                )
        f.close
        # set default indicators
        animal.is_measured!(:sex, r.sex)
        animal.is_measured!(:reproductor, false)
        animal.is_measured!(:net_weight, 55.45.in_kilogram, :at => r.born_on.to_datetime)
        animal.is_measured!(:net_weight, 75.89.in_kilogram, :at => (r.born_on.to_datetime + 2.months))
        animal.is_measured!(:net_weight, 89.56.in_kilogram, :at => (r.born_on.to_datetime + 4.months))
        animal.is_measured!(:net_weight, 129.56.in_kilogram, :at => (r.born_on.to_datetime + 8.months))
        animal.is_measured!(:animal_disease_state, :healthy)
        animal.is_measured!(:animal_disease_state, :sick, :at => (Time.now - 2.days))
        animal.is_measured!(:animal_disease_state, :healthy, :at => (Time.now - 3.days))
        if place_gen and group_gen1
          # place the current animal in the default group with born_at
          ProductLocalization.create!(:container_id => place_gen.id, :product_id => animal.id, :nature => :interior, :started_at => r.arrived_on, :stopped_at => r.departed_on, :arrival_cause => r.arrival_cause, :departure_cause => r.departure_cause)
          ProductMembership.create!(:member_id => animal.id, :group_id => group_gen1.id, :started_at => r.arrived_on, :stopped_at => r.departed_on )
        end

        # case = GENISSE 3
      elsif r.born_on > (Date.today - 28.months) and r.born_on < (Date.today - 12.months) and r.sex == :female
        f = File.open(pictures.sample)
        animal = Animal.create!(:variant_id => cow_v.id, :name => r.name, :variety => "bos",
                                :identification_number => r.identification_number, :work_number => r.work_number,
                                :born_at => r.born_on, :dead_at => r.departed_on,
                                :picture => f, :owner_id => Entity.of_company.id
                                )
        f.close
        # set default indicators
        animal.is_measured!(:sex, r.sex)
        animal.is_measured!(:reproductor, true)
        animal.is_measured!(:net_weight, 55.45.in_kilogram, :at => r.born_on.to_datetime)
        animal.is_measured!(:net_weight, 75.89.in_kilogram, :at => (r.born_on.to_datetime + 2.months))
        animal.is_measured!(:net_weight, 89.56.in_kilogram, :at => (r.born_on.to_datetime + 4.months))
        animal.is_measured!(:net_weight, 129.56.in_kilogram, :at => (r.born_on.to_datetime + 8.months))
        animal.is_measured!(:net_weight, 189.56.in_kilogram, :at => (r.born_on.to_datetime + 12.months))
        animal.is_measured!(:animal_disease_state, :healthy)
        animal.is_measured!(:animal_disease_state, :sick, :at => (Time.now - 2.days))
        animal.is_measured!(:animal_disease_state, :healthy, :at => (Time.now - 3.days))
        if place_gen and group_gen3
          # place the current animal in the default group with born_at
          ProductLocalization.create!(:container_id => place_gen.id, :product_id => animal.id, :nature => :interior, :started_at => r.arrived_on, :stopped_at => r.departed_on, :arrival_cause => r.arrival_cause, :departure_cause => r.departure_cause)
          ProductMembership.create!(:member_id => animal.id, :group_id => group_gen3.id, :started_at => r.arrived_on, :stopped_at => r.departed_on )
        end

        # case = VL
      elsif r.born_on > (Date.today - 20.years) and r.born_on < (Date.today - 28.months) and r.sex == :female
        f = File.open(pictures.sample)
        animal = Animal.create!(:variant_id => cow_vl.id, :name => r.name, :variety => "bos",
                                :identification_number => r.identification_number, :work_number => r.work_number,
                                :born_at => r.born_on, :dead_at => r.departed_on,
                                :picture => f, :owner_id => Entity.of_company.id
                                )
        f.close
        # set default indicators
        animal.is_measured!(:sex, r.sex)
        animal.is_measured!(:reproductor, true)
        animal.is_measured!(:net_weight, 55.45.in_kilogram, :at => r.born_on.to_datetime)
        animal.is_measured!(:net_weight, 75.89.in_kilogram, :at => (r.born_on.to_datetime + 2.months))
        animal.is_measured!(:net_weight, 89.56.in_kilogram, :at => (r.born_on.to_datetime + 4.months))
        animal.is_measured!(:net_weight, 129.56.in_kilogram, :at => (r.born_on.to_datetime + 8.months))
        animal.is_measured!(:net_weight, 189.56.in_kilogram, :at => (r.born_on.to_datetime + 12.months))
        animal.is_measured!(:net_weight, 389.56.in_kilogram, :at => (r.born_on.to_datetime + 24.months))
        animal.is_measured!(:animal_disease_state, :healthy)
        animal.is_measured!(:animal_disease_state, :sick, :at => (Time.now - 2.days))
        animal.is_measured!(:animal_disease_state, :healthy, :at => (Time.now - 3.days))
        if place_vl and group_vl
          # place the current animal in the default group with born_at
          ProductLocalization.create!(:container_id => place_vl.id, :product_id => animal.id, :nature => :interior, :started_at => r.arrived_on, :stopped_at => r.departed_on, :arrival_cause => r.arrival_cause, :departure_cause => r.departure_cause)
          ProductMembership.create!(:member_id => animal.id, :group_id => group_vl.id, :started_at => r.arrived_on, :stopped_at => r.departed_on )
        end

        # case = TAURILLON
      elsif r.born_on > (Date.today - 10.years) and r.born_on < (Date.today - 3.months) and r.sex == :male
        f = File.open(photo_taur)
        animal = Animal.create!(:variant_id => cow_taur.id, :name => r.name, :variety => "bos",
                                :identification_number => r.identification_number, :work_number => r.work_number,
                                :born_at => r.born_on, :dead_at => r.departed_on,
                                :picture => f, :owner_id => Entity.of_company.id
                                )
        f.close
        # set default indicators
        animal.is_measured!(:sex, r.sex)
        animal.is_measured!(:reproductor, false)
        animal.is_measured!(:net_weight, 55.45.in_kilogram, :at => r.born_on.to_datetime)
        animal.is_measured!(:net_weight, 75.89.in_kilogram, :at => (r.born_on.to_datetime + 2.months))
        animal.is_measured!(:net_weight, 89.56.in_kilogram, :at => (r.born_on.to_datetime + 4.months))
        animal.is_measured!(:net_weight, 129.56.in_kilogram, :at => (r.born_on.to_datetime + 8.months))
        animal.is_measured!(:net_weight, 189.56.in_kilogram, :at => (r.born_on.to_datetime + 12.months))
        animal.is_measured!(:net_weight, 389.56.in_kilogram, :at => (r.born_on.to_datetime + 24.months))
        animal.is_measured!(:animal_disease_state, :healthy)
        animal.is_measured!(:animal_disease_state, :sick, :at => (Time.now - 2.days))
        animal.is_measured!(:animal_disease_state, :healthy, :at => (Time.now - 3.days))
        if place_taur and group_taur
          # place the current animal in the default group with born_at
          ProductLocalization.create!(:container_id => place_taur.id, :product_id => animal.id, :nature => :interior, :started_at => r.arrived_on, :stopped_at => r.departed_on, :arrival_cause => r.arrival_cause, :departure_cause => r.departure_cause)
          ProductMembership.create!(:member_id => animal.id, :group_id => group_taur.id, :started_at => r.arrived_on, :stopped_at => r.departed_on )
        end

      end
      w.check_point
    end

  end

  Ekylibre::fixturize :upra_reproductor_list_import do |w|
    file = Rails.root.join("test", "fixtures", "files", "liste_males_reproducteurs_race_normande_ISU_130.txt")
    picture_trepro = Dir.glob(Rails.root.join("test", "fixtures", "files", "animals", "taurillon.jpg"))
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
      animal = Animal.create!(:variant_id => cow_trepro.id, :name => r.name, :variety => "bos", :identification_number => r.identification_number[-10..-1], :external => true, :owner_id => Entity.where(:of_company => false).all.sample.id)
      # set default indicators
      animal.is_measured!(:sex, :male)
      animal.is_measured!(:reproductor, true)
      animal.is_measured!(:isu_index,  r.isu.in_unity,  :at => now)
      animal.is_measured!(:inel_index, r.inel.in_unity, :at => now)
      animal.is_measured!(:tp_index,   r.tp.in_unity,   :at => now)
      animal.is_measured!(:tb_index,   r.tb.in_unity,   :at => now)

      w.check_point

    end
  end


  Ekylibre::fixturize :assign_animal_parent_with_inventory do |w|

    file = Rails.root.join("test", "fixtures", "files", "animals-synel17_inventory.csv")
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
                                         :identification_number => r.mother_identification_number, :work_number => r.mother_identification_number[-4..-1], :owner_id => Entity.of_company.id
                                         )

          # set default indicators
          animal_mother.is_measured!(:sex, :female)
          animal_mother.is_measured!(:reproductor, true)
          animal_mother.is_measured!(:animal_disease_state, :healthy)
          animal_mother.is_measured!(:animal_disease_state, :sick, :at => (Time.now - 2.days))
          animal_mother.is_measured!(:animal_disease_state, :healthy, :at => (Time.now - 3.days))
          animal.mother = animal_mother
          end
        end
        if animal_father = Animal.find_by_identification_number(r.father_identification_number)
          animal.father = animal_father
        else
          unless r.father_identification_number.blank?
          # case = TAUREAU REPRO
          animal_father = Animal.create!(:variant_id => cow_trepro.id, :name => r.father_name, :variety => "bos", :identification_number => r.father_identification_number, :external => true, :owner_id => Entity.where(:of_company => false).all.sample.id)
          # set default indicators
          animal_father.is_measured!(:sex, :male)
          animal_father.is_measured!(:reproductor, true)
          animal.father = animal_father
          end
        end
        animal.save!
        w.check_point
      end
    end

  end

end
