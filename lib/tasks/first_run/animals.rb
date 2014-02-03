# -*- coding: utf-8 -*-
load_data :animals do |loader|

  # add animals credentials in preferences
  synel_login = Preference.where(:nature => :string, :name => "services.synel17.login", :string_value => "17387001").first_or_create
  cattling_number = Preference.where(:nature => :string, :name => "entity_identification.ede.cattling_number", :string_value => "FR17387001").first_or_create
  owner_number = Preference.where(:nature => :string, :name => "entity_identification.ede.owner_number", :string_value => "FR01700006989").first_or_create

  # # import variant for creating animal
  # cow_vl     = ProductNatureVariant.import_from_nomenclature(:female_adult_cow)
  # cow_trepro = ProductNatureVariant.import_from_nomenclature(:male_adult_cow)
  # cow_gen    = ProductNatureVariant.import_from_nomenclature(:female_young_cow)
  # cow_taur   = ProductNatureVariant.import_from_nomenclature(:male_young_cow)
  # cow_v      = ProductNatureVariant.import_from_nomenclature(:calf)
  # herd       = ProductNatureVariant.import_from_nomenclature(:cattle_herd)

  # # find place for creating animal
  # place_v = BuildingDivision.find_by_work_number("B09_D1")
  # place_gen = BuildingDivision.find_by_work_number("B03_D9")
  # place_taur = BuildingDivision.find_by_work_number("B04_D4")
  # place_vl = BuildingDivision.find_by_work_number("B07_D2")



  # loader.count :animal_natures do |w|
  #   #############################################################################
  #   for group in [{:name => "Vaches Laitières", :work_number => "VL", :default_storage => place_vl},
  #                 {:name => "Génisses 3",  :work_number => "GEN_3", :default_storage => place_gen},
  #                 {:name => "Génisses 2",  :work_number => "GEN_2", :default_storage => place_gen},
  #                 {:name => "Génisses 1",  :work_number => "GEN_1", :default_storage => place_gen},
  #                 {:name => "Veaux Niche", :work_number => "VEAU", :description => "Veaux en niche individuel", :default_storage => place_v},
  #                 {:name => "Veaux 8-15j", :work_number => "VEAU_8_15", :description => "Veaux vendus à 8-15 J", :default_storage => place_v},
  #                 {:name => "Taurillons", :work_number => "TAUR", :description => "Taurillons vendus entre 21 et 26 mois", :default_storage => place_taur}
  #                ]
  #     unless AnimalGroup.find_by_work_number(group[:work_number])
  #       AnimalGroup.create!({ :variant_id => herd.id}.merge(group))
  #     end
  #     w.check_point
  #   end
  # end

  # # find groupe for creating animal
  # group_v = AnimalGroup.find_by_work_number("VEAU")
  # group_gen1 = AnimalGroup.find_by_work_number("GEN_1")
  # group_gen2 = AnimalGroup.find_by_work_number("GEN_2")
  # group_gen3 = AnimalGroup.find_by_work_number("GEN_3")
  # group_taur = AnimalGroup.find_by_work_number("TAUR")
  # group_vl = AnimalGroup.find_by_work_number("VL")



  groups = []

  file = loader.path("animal_groups.csv")
  if file.exist?
    loader.count :animal_groups do |w|
      CSV.foreach(file, headers: true) do |row|
        r = OpenStruct.new(name: row[0],
                           nature: row[1].to_sym,
                           member_nature: row[2].to_sym,
                           code: row[3],
                           minimum_age: (row[4].blank? ? nil : row[4].to_i),
                           maximum_age: (row[5].blank? ? nil : row[5].to_i),
                           sex: (row[6].blank? ? nil : row[6].to_sym),
                           place: (row[7].blank? ? nil : row[7].to_sym),
                           description: row[8].to_s,
                           record: nil
                           )


        unless r.record = AnimalGroup.find_by_work_number(r.code)
          picture_path = loader.path("animal_groups", "#{r.code}.jpg")
          f = (picture_path.exist? ? File.open(picture_path) : nil)
          r.record = AnimalGroup.create!(name: r.name,
                                         picture: f,
                                         work_number: r.code,
                                         variant: ProductNatureVariant.import_from_nomenclature(r.nature),
                                         default_storage: BuildingDivision.find_by(work_number: r.place),
                                         description: r.description)
          f.close if f
        end

        groups << r
        w.check_point
      end
    end
  end




  file = loader.path("animals-synel17.csv")
  if file.exist?

    loader.count :synel_animal_import do |w|
      #############################################################################

      # initial_arrival_causes = {"N" => :birth, "A" => :purchase, "P" => :housing, "" => :other }
      # arrival_causes = {"N" => :interior, "A" => :exterior, "P" => :exterior, "" => :interior }
      # departure_causes = {"M" => :exterior, "B" => :exterior, "" => :exterior, "C" => :interior , "E" => :exterior}


      # pictures = Dir.glob(loader.path("animals-ld", "*.jpg"))
      # photo_taur = loader.path("animals", "taurillon.jpg")
      # photo_v = loader.path("animals", "veau.jpg")
      CSV.foreach(file, encoding: "CP1252", col_sep: ";", headers: true) do |row|
        next if row[4].blank?
        born_on = (row[4].blank? ? nil : Date.civil(*row[4].to_s.split(/\//).reverse.map(&:to_i)))
        dead_on = (row[10].blank? ? nil : Date.civil(*row[10].to_s.split(/\//).reverse.map(&:to_i)))
        r = OpenStruct.new(:country => row[0],
                           :identification_number => row[1],
                           :work_number => row[2],
                           :name => (row[3].blank? ? Faker::Name.first_name + " (MN)" : row[3].capitalize),
                           :born_on => born_on,
                           born_at: (born_on ? born_on.to_datetime + 10.hours : nil),
                           age: (born_on ? (Date.today - born_on) : 0),
                           :corabo => row[5],
                           :sex => (row[6] == "F" ? :female : :male),
                           # :arrival_cause => (arrival_causes[row[7]] || row[7]),
                           # :initial_arrival_cause => (initial_arrival_causes[row[7]] || row[7]),
                           :arrived_on => (row[8].blank? ? nil : Date.civil(*row[8].to_s.split(/\//).reverse.map(&:to_i))),
                           # :departure_cause => (departure_causes[row[9]] ||row[9]),
                           :departed_on => dead_on,
                           dead_at: (dead_on ? dead_on.to_datetime : nil)
                           )

        unless group = groups.detect do |g|
            (g.sex.blank? or g.sex == r.sex) and (g.minimal_age.blank? or r.age >= g.minimal_age) and (g.maximal_age.blank? or r.age < g.maximal_age)
          end
          raise "Cannot find a valid group for the given"
        end

        picture_path = loader.path("animals", "#{r.work_number}.jpg")
        f = (picture_path.exist? ? File.open(picture_path) : nil)
        variant = ProductNatureVariant.import_from_nomenclature(group.member_nature)
        animal = Animal.create!(variant: variant,
                                name: r.name,
                                variety: variant.variety,
                                identification_number: r.identification_number,
                                work_number: r.work_number,
                                initial_born_at: r.born_at,
                                initial_dead_at: r.dead_at,
                                initial_owner: Entity.of_company,
                                initial_container: group.record.default_storage,
                                picture: f,
                                default_storage: group.record.default_storage
                                )
        f.close if f
        animal.is_measured!(:sex, r.sex, at: r.born_at)

        weighted_at = r.born_at
        variation = 0.05
        while (r.dead_at.nil? or weighted_at < r.dead_at) and weighted_at < Time.now
          age = (weighted_at - r.born_at).to_f
          weight = (age < 990 ? 700 * Math.sin(age / (100 * 2 * Math::PI)) + 50.0 : 750)
          weight += rand(weight * variation * 2) - (weight * variation)
          animal.is_measured!(:net_mass, weight.in_kilogram.round(1), at: weighted_at)
          weighted_at += (70 + rand(40)).days + 30.minutes - rand(60).minutes
        end

        animal.is_measured!(:healthy, true, at: (Time.now - 3.days))
        animal.is_measured!(:healthy, false, at: (Time.now - 2.days))
        animal.is_measured!(:healthy, true)

        group.record.add(animal, r.arrived_on)
        group.record.remove(animal, r.departed_on) if r.departed_on


        # # case = VEAU
        # if r.born_on > (Date.today - 3.months) and r.born_on < (Date.today)
        #   f = File.open(photo_v)
        #   animal = Animal.create!(:variant_id => cow_v.id, :name => r.name, :variety => "bos", :identification_number => r.identification_number,
        #                           :work_number => r.work_number, :born_at => r.born_at, :dead_at => r.departed_on,
        #                           :picture => f, :initial_owner => Entity.of_company, :initial_container => place_v, :default_storage => place_v
        #                           )
        #   f.close
        #   # set default indicators
        #   animal.is_measured!(:sex, r.sex, at: r.born_on.to_datetime)
        #   animal.is_measured!(:net_mass, 55.45.in_kilogram, at: r.born_on.to_datetime)
        #   animal.is_measured!(:net_mass, 75.89.in_kilogram, at: (r.born_on.to_datetime + 2.months))
        #   animal.is_measured!(:healthy, true)
        #   animal.is_measured!(:healthy, false, at: (Time.now - 2.days))
        #   animal.is_measured!(:healthy, true, at: (Time.now - 3.days))
        #   # place the current animal in the default group with born_at
        #   if place_v and group_v
        #     ProductLocalization.create!(:container_id => place_v.id, :product_id => animal.id, :started_at => r.arrived_on, :stopped_at => r.departed_on)
        #     # add animal in group
        #     group_v.add(animal, r.arrived_on)
        #     # remove animal from group if r.departed_on
        #     group_v.remove(animal, r.departed_on) if r.departed_on
        #   end

        #   # case = GENISSE 1
        # elsif r.born_on > (Date.today - 12.months) and r.born_on < (Date.today - 3.months) and r.sex == :female
        #   f = File.open(pictures.sample)
        #   animal = Animal.create!(:variant_id => cow_gen.id, :name => r.name, :variety => "bos",
        #                           :identification_number => r.identification_number, :work_number => r.work_number,
        #                           :born_at => r.born_on, :dead_at => r.departed_on,
        #                           :picture => f, :initial_owner => Entity.of_company, :initial_container => place_gen, :default_storage => place_gen
        #                           )
        #   f.close
        #   # set default indicators
        #   animal.is_measured!(:net_mass, 55.45.in_kilogram, at: r.born_on.to_datetime)
        #   animal.is_measured!(:net_mass, 75.89.in_kilogram, at: (r.born_on.to_datetime + 2.months))
        #   animal.is_measured!(:net_mass, 89.56.in_kilogram, at: (r.born_on.to_datetime + 4.months))
        #   animal.is_measured!(:net_mass, 129.56.in_kilogram, at: (r.born_on.to_datetime + 8.months))
        #   animal.is_measured!(:healthy, true)
        #   animal.is_measured!(:healthy, false, at: (Time.now - 2.days))
        #   animal.is_measured!(:healthy, true, at: (Time.now - 3.days))
        #   if place_gen and group_gen1
        #     # place the current animal in the default group with born_at
        #     ProductLocalization.create!(:container_id => place_gen.id, :product_id => animal.id, :started_at => r.arrived_on, :stopped_at => r.departed_on)
        #     # add animal in group
        #     group_gen1.add(animal, r.arrived_on)
        #     # remove animal from group if r.departed_on
        #     group_gen1.remove(animal, r.departed_on) if r.departed_on
        #   end

        #   # case = GENISSE 3
        # elsif r.born_on > (Date.today - 28.months) and r.born_on < (Date.today - 12.months) and r.sex == :female
        #   f = File.open(pictures.sample)
        #   animal = Animal.create!(:variant_id => cow_gen.id, :name => r.name, :variety => "bos",
        #                           :identification_number => r.identification_number, :work_number => r.work_number,
        #                           :born_at => r.born_on, :dead_at => r.departed_on,
        #                           :picture => f, :initial_owner => Entity.of_company, :initial_container => place_gen, :default_storage => place_gen
        #                           )
        #   f.close
        #   # set default indicators
        #   animal.is_measured!(:net_mass, 55.45.in_kilogram, at: r.born_on.to_datetime)
        #   animal.is_measured!(:net_mass, 75.89.in_kilogram, at: (r.born_on.to_datetime + 2.months))
        #   animal.is_measured!(:net_mass, 89.56.in_kilogram, at: (r.born_on.to_datetime + 4.months))
        #   animal.is_measured!(:net_mass, 129.56.in_kilogram, at: (r.born_on.to_datetime + 8.months))
        #   animal.is_measured!(:net_mass, 189.56.in_kilogram, at: (r.born_on.to_datetime + 12.months))
        #   animal.is_measured!(:healthy, true)
        #   animal.is_measured!(:healthy, false, at: (Time.now - 2.days))
        #   animal.is_measured!(:healthy, true, at: (Time.now - 3.days))
        #   if place_gen and group_gen3
        #     # place the current animal in the default group with born_at
        #     ProductLocalization.create!(:container_id => place_gen.id, :product_id => animal.id, :started_at => r.arrived_on, :stopped_at => r.departed_on)
        #     # add animal in group
        #     group_gen3.add(animal, r.arrived_on)
        #     # remove animal from group if r.departed_on
        #     group_gen3.remove(animal, r.departed_on) if r.departed_on
        #   end

        #   # case = VL
        # elsif r.born_on > (Date.today - 20.years) and r.born_on < (Date.today - 28.months) and r.sex == :female
        #   f = File.open(pictures.sample)
        #   animal = Animal.create!(:variant_id => cow_vl.id, :name => r.name, :variety => "bos",
        #                           :identification_number => r.identification_number, :work_number => r.work_number,
        #                           :born_at => r.born_on, :dead_at => r.departed_on,
        #                           :picture => f, :initial_owner => Entity.of_company, :initial_container => place_vl, :default_storage => place_vl
        #                           )
        #   f.close
        #   # set default indicators
        #   animal.is_measured!(:net_mass, 55.45.in_kilogram, at: r.born_on.to_datetime)
        #   animal.is_measured!(:net_mass, 75.89.in_kilogram, at: (r.born_on.to_datetime + 2.months))
        #   animal.is_measured!(:net_mass, 89.56.in_kilogram, at: (r.born_on.to_datetime + 4.months))
        #   animal.is_measured!(:net_mass, 129.56.in_kilogram, at: (r.born_on.to_datetime + 8.months))
        #   animal.is_measured!(:net_mass, 189.56.in_kilogram, at: (r.born_on.to_datetime + 12.months))
        #   animal.is_measured!(:net_mass, 389.56.in_kilogram, at: (r.born_on.to_datetime + 24.months))
        #   animal.is_measured!(:healthy, true)
        #   animal.is_measured!(:healthy, false, at: (Time.now - 2.days))
        #   animal.is_measured!(:healthy, true, at: (Time.now - 3.days))
        #   if place_vl and group_vl
        #     # place the current animal in the default group with born_at
        #     ProductLocalization.create!(:container_id => place_vl.id, :product_id => animal.id, :started_at => r.arrived_on, :stopped_at => r.departed_on)
        #     # add animal in group
        #     group_vl.add(animal, r.arrived_on)
        #     # remove animal from group if r.departed_on
        #     group_vl.remove(animal, r.departed_on) if r.departed_on
        #   end

        #   # case = TAURILLON
        # elsif r.born_on > (Date.today - 10.years) and r.born_on < (Date.today - 3.months) and r.sex == :male
        #   f = File.open(photo_taur)
        #   animal = Animal.create!(:variant_id => cow_taur.id, :name => r.name, :variety => "bos",
        #                           :identification_number => r.identification_number, :work_number => r.work_number,
        #                           :born_at => r.born_on, :dead_at => r.departed_on,
        #                           :picture => f, :initial_owner => Entity.of_company, :initial_container => place_taur, :default_storage => place_taur
        #                           )
        #   f.close
        #   # set default indicators
        #   animal.is_measured!(:net_mass, 55.45.in_kilogram, at: r.born_on.to_datetime)
        #   animal.is_measured!(:net_mass, 75.89.in_kilogram, at: (r.born_on.to_datetime + 2.months))
        #   animal.is_measured!(:net_mass, 89.56.in_kilogram, at: (r.born_on.to_datetime + 4.months))
        #   animal.is_measured!(:net_mass, 129.56.in_kilogram, at: (r.born_on.to_datetime + 8.months))
        #   animal.is_measured!(:net_mass, 189.56.in_kilogram, at: (r.born_on.to_datetime + 12.months))
        #   animal.is_measured!(:net_mass, 389.56.in_kilogram, at: (r.born_on.to_datetime + 24.months))
        #   animal.is_measured!(:healthy, true)
        #   animal.is_measured!(:healthy, false, at: (Time.now - 2.days))
        #   animal.is_measured!(:healthy, true, at: (Time.now - 3.days))
        #   if place_taur and group_taur
        #     # place the current animal in the default group with born_at
        #     ProductLocalization.create!(:container_id => place_taur.id, :product_id => animal.id, :started_at => r.arrived_on, :stopped_at => r.departed_on)
        #     # add animal in group
        #     group_taur.add(animal, r.arrived_on)
        #     # remove animal from group if r.departed_on
        #     group_taur.remove(animal, r.departed_on) if r.departed_on
        #   end

        # end
        w.check_point

      end
    end
  end


  male_adult_cow   = ProductNatureVariant.import_from_nomenclature(:male_adult_cow)
  female_adult_cow = ProductNatureVariant.import_from_nomenclature(:female_adult_cow)
  place   = BuildingDivision.last # find_by_work_number("B07_D2")

  file = loader.path("liste_males_reproducteurs_race_normande_ISU_130.txt")
  if file.exist?
    loader.count :upra_reproductor_list_import do |w|
      now = Time.now - 2.months
      CSV.foreach(file, encoding: "CP1252", col_sep: "\t", headers: true) do |row|
        next if row[4].blank?
        r = OpenStruct.new(:order => row[0],
                           :name => row[1],
                           :identification_number => row[2],
                           :work_number => row[2][-4..-1],
                           :father => row[3],
                           :provider => row[4],
                           :isu => row[5].to_i,
                           :inel => row[9].to_i,
                           :tp => row[10].to_f,
                           :tb => row[11].to_f
                           )
        picture_path = loader.path("animals", "#{r.work_number}.jpg")
        f = (picture_path.exist? ? File.open(picture_path) : nil)
        animal = Animal.create!(:variant_id => male_adult_cow.id, :name => r.name, :variety => "bos", :identification_number => r.identification_number[-10..-1], :initial_owner => Entity.where(:of_company => false).all.sample, picture: f)
        f.close if f
        # set default indicators
        animal.is_measured!(:unique_synthesis_index,         r.isu.in_unity,  at: now)
        animal.is_measured!(:economical_milk_index,          r.inel.in_unity, at: now)
        animal.is_measured!(:protein_concentration_index,    r.tp.in_unity,   at: now)
        animal.is_measured!(:fat_matter_concentration_index, r.tb.in_unity,   at: now)
        # put in an external localization
        animal.localizations.create!(nature: :exterior)
        w.check_point
      end
    end
  end


  file = loader.path("animals-synel17_inventory.csv")
  if file.exist?
    loader.count :assign_parents_with_inventory do |w|

      CSV.foreach(file, encoding: "CP1252", col_sep: ",", headers: true) do |row|
        next if row[4].blank?
        r = OpenStruct.new(:identification_number => row[3],
                           :name => (row[4].blank? ? Faker::Name.first_name+" (MN)" : row[4].capitalize),
                           :mother_identification_number => row[13],
                           :mother_work_number => (row[13] ? row[13][-4..-1] : nil),
                           :mother_name => (row[14].blank? ? Faker::Name.first_name : row[14].capitalize),
                           :father_identification_number => row[16],
                           :father_work_number => (row[16] ? row[16][-4..-1] : nil),
                           :father_name => (row[17].blank? ? Faker::Name.first_name : row[17].capitalize)
                           )
        # check if animal is present in DB
        next unless animal = Animal.find_by_identification_number(r.identification_number)

        linkeds = {}

        # Find or create mother
        unless linkeds[:mother] = Animal.find_by_identification_number(r.mother_identification_number)
          unless r.mother_identification_number.blank?
            picture_path = loader.path("animals", "#{r.mother_work_number}.jpg")
            f = (picture_path.exist? ? File.open(picture_path) : nil)
            linkeds[:mother] = Animal.create!(:variant_id => female_adult_cow.id,
                                              :name => r.mother_name,
                                              :variety => "bos",
                                              :identification_number => r.mother_identification_number,
                                              work_number: r.mother_work_number,
                                              picture: f,
                                              :initial_owner => Entity.of_company,
                                              :initial_container => place,
                                              :default_storage => place)
            f.close if f
          end
        end

        # Find or create father
        unless linkeds[:father] = Animal.find_by_identification_number(r.father_identification_number)
          unless r.father_identification_number.blank?
            picture_path = loader.path("animals", "#{r.father_work_number}.jpg")
            f = (picture_path.exist? ? File.open(picture_path) : nil)
            linkeds[:father] = Animal.create!(:variant_id => male_adult_cow.id,
                                              :name => r.father_name,
                                              :variety => "bos",
                                              :identification_number => r.father_identification_number,
                                              work_number: r.father_work_number,
                                              picture: f,
                                              :initial_owner => Entity.where(of_company: false).all.sample)
            f.close if f
          end
        end

        for nature in [:mother, :father]
          next unless linkeds[nature]
          unless link = animal.links.find_by(nature: nature)
            link = animal.links.new(nature: nature, started_at: animal.born_at)
          end
          link.linked = linkeds[nature]
          link.save!
        end

        w.check_point
      end

    end
  end

end
