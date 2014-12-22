# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :animals do |first_run|

  groups = []

  file = first_run.path("alamano", "animal_groups.csv")
  if file.exist?
    # find animals credentials in preferences
    cattling_root_number = Identifier.find_by_nature(:cattling_root_number).value


    file = first_run.path("alamano", "animal_groups.csv")
    if file.exist?
      first_run.count :animal_groups do |w|
        CSV.foreach(file, headers: true) do |row|
          r = OpenStruct.new(name: row[0],
                             nature: row[1].to_sym,
                             member_nature: (row[2].blank? ? nil : row[2].to_sym),
                             code: row[3],
                             minimum_age: (row[4].blank? ? nil : row[4].to_i),
          maximum_age: (row[5].blank? ? nil : row[5].to_i),
          sex: (row[6].blank? ? nil : row[6].to_sym),
          place: (row[7].blank? ? nil : row[7].to_sym),
          indicators_at: (row[8].blank? ? (Date.today) : row[8]).to_datetime,
          indicators: row[9].blank? ? {} : row[9].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
            h[i.first.strip.downcase.to_sym] = i.second
            h
                             },
                             record: nil
                             )


          unless r.record = AnimalGroup.find_by(work_number: r.code)
            r.record = AnimalGroup.create!(name: r.name,
                                           work_number: r.code,
                                           initial_born_at: r.indicators_at,
                                           variant: ProductNatureVariant.import_from_nomenclature(r.nature),
                                           default_storage: BuildingDivision.find_by(work_number: r.place)
                                           )
            # create indicators linked to equipment
            for indicator, value in r.indicators
              r.record.read!(indicator, value, at: r.indicators_at, force: true)
            end
            r.record.initial_population = r.record.population
            r.record.save!
          end

          groups << r
          w.check_point
        end
      end
    end

    file = first_run.path("alamano", "animals.csv")
    if file.exist?
      first_run.count :animals do |w|
        CSV.foreach(file, headers: true) do |row|
          next if row[0].blank?
          r = OpenStruct.new(name: row[0],
                             nature: row[1].to_sym,
                             code: row[2].to_sym,
                             place: (row[3].blank? ? nil : row[3].to_s),
                             group: (row[4].blank? ? nil : row[4].to_s),
                             born_at: (row[5].blank? ? (Date.today) : row[5]).to_datetime,
                             variety: (row[6].blank? ? nil : row[6].to_sym),
                             initial_owner: (row[7].blank? ? nil : row[7].to_s),
                             indicators: row[8].blank? ? {} : row[8].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
                               h[i.first.strip.downcase.to_sym] = i.second
                               h
                             },
                             record: nil
          )

          unless r.record = Animal.find_by(work_number: r.code)
            r.record = Animal.create!(name: r.name,
                                           work_number: r.code,
                                           identification_number: r.code,
                                           initial_born_at: r.born_at,
                                           variant: ProductNatureVariant.import_from_nomenclature(r.nature),
                                           default_storage: BuildingDivision.find_by(work_number: r.place)
            )
            # create indicators linked to animal
            for indicator, value in r.indicators
              r.record.read!(indicator, value, at: r.born_at, force: true)
            end
            r.record.initial_population = r.record.population
            r.record.variety = r.variety if r.variety
            r.record.initial_owner = r.initial_owner if r.initial_owner
            if r.group
              animal_group = AnimalGroup.find_by(work_number: r.group)
              animal_group.add(r.record, r.born_at) if animal_group
            end
            r.record.save!
          end

          w.check_point
        end
      end
    end



    male_adult_cow   = ProductNatureVariant.import_from_nomenclature(:male_adult_cow)
    female_adult_cow = ProductNatureVariant.import_from_nomenclature(:female_adult_cow)
    place   = BuildingDivision.last # find_by_work_number("B07_D2")
    owners = Entity.where(:of_company => false).all

    file = first_run.path("alamano", "liste_males_reproducteurs.txt")
    if file.exist?
      first_run.count :upra_reproductor_list_import do |w|
        now = Time.now - 2.months
        CSV.foreach(file, encoding: "CP1252", col_sep: "\t", headers: true) do |row|
          next if row[4].blank?
          r = OpenStruct.new(:order => row[0],
                             :name => row[1],
                             :identification_number => row[2],
                             #:work_number => row[2][-4..-1],
                             #:father => row[3],
                             #:provider => row[4],
                             :isu => row[5].to_i,
                             :inel => row[9].to_i,
                             :tp => row[10].to_f,
                             :tb => row[11].to_f
                             )
          animal = Animal.create!(:variant_id => male_adult_cow.id,
                                  :name => r.name, :variety => 'bos_taurus_normande',
                                  :born_at => '1900-01-01 01:00',
                                  :identification_number => r.identification_number[-10..-1],
                                  :initial_owner => owners.sample)
          # set default indicators
          animal.read!(:unique_synthesis_index,         r.isu.in_unity,  at: now)
          animal.read!(:economical_milk_index,          r.inel.in_unity, at: now)
          animal.read!(:protein_concentration_index,    r.tp.in_unity,   at: now)
          animal.read!(:fat_matter_concentration_index, r.tb.in_unity,   at: now)
          # put in an external localization
          animal.localizations.create!(nature: :exterior)
          w.check_point
        end
      end
    end

    # attach picture if exist for each group
    for group in AnimalGroup.all
      picture_path = first_run.path("alamano", "animal_groups_pictures", "#{group.work_number}.jpg")
      f = (picture_path.exist? ? File.open(picture_path) : nil)
      if f
        group.picture = f
        group.save!
        f.close
      end
    end

    # build name of synel animals file
    if service = NetService.find_by(reference_name: :synel)
      synel_first_part = service.identifiers.find_by(nature: :synel_username).value.to_s
      synel_second_part = Identifier.find_by(nature: :cattling_number).value.to_s
      synel_last_part = "IP"
      synel_file_extension = ".csv"
      if synel_first_part and synel_second_part
        synel_file_name = synel_first_part + synel_second_part + synel_last_part + synel_file_extension
      end
    else synel_file_name = "animaux.csv"
    end

    is_a_demo_instance = Preference.get!(:demo, false, :boolean).value
    variants = {}
    owner = Entity.of_company
    file = first_run.path("synel", synel_file_name.to_s)
    if file.exist?
      now = Time.now
      first_run.count :synel_animal_import do |w|
        #############################################################################
        CSV.foreach(file, encoding: "CP1252", col_sep: ";", headers: true) do |row|
          next if row[4].blank?
          born_on = (row[4].blank? ? nil : Date.parse(row[4]))
          dead_on = (row[10].blank? ? nil : Date.parse(row[10]))
          r = OpenStruct.new(:country => row[0],
                             :identification_number => row[1],
                             :work_number => row[2],
                             :name => (row[3].blank? ? Faker::Name.first_name + " (MN)" : row[3].capitalize),
                             :born_on => born_on,
                             born_at: (born_on ? born_on.to_datetime + 10.hours : nil),
                             age: (born_on ? (Date.today - born_on) : 0).to_f,
                             :corabo => row[5],
                             :sex => (row[6] == "F" ? :female : :male),
                             # :arrival_cause => (arrival_causes[row[7]] || row[7]),
                             # :initial_arrival_cause => (initial_arrival_causes[row[7]] || row[7]),
                             :arrived_on => (row[8].blank? ? nil : Date.parse(row[8])),
                             # :departure_cause => (departure_causes[row[9]] ||row[9]),
                             :departed_on => dead_on,
                             dead_at: (dead_on ? dead_on.to_datetime : nil)
                             )
          unless animal = Animal.find_by(identification_number: r.identification_number)
            unless group = groups.detect do |g|
                (g.sex.blank? or g.sex == r.sex) and
                (g.minimum_age.blank? or r.age >= g.minimum_age) and
                (g.maximum_age.blank? or r.age < g.maximum_age)
              end
              raise "Cannot find a valid group for the given (for #{r.inspect})"
            end

            variants[group.member_nature] ||= ProductNatureVariant.import_from_nomenclature(group.member_nature)
            variant = variants[group.member_nature]

            # find a bos variety from corabo field in file
            items = Nomen::Varieties.where(french_race_code: r.corabo)
            if items
              bos_variety = items.first.name
            else
              bos_variety = variant.variety
            end

            animal = Animal.create!(
               variant: variant,
               name: r.name,
               variety: bos_variety,
               identification_number: r.identification_number,
               work_number: r.work_number,
               initial_born_at: r.born_at,
               initial_dead_at: r.dead_at,
               initial_owner: owner,
               # initial_container: group.record.default_storage,
               default_storage: group.record.default_storage
               )

            # Sex is already known but not if the group has no sex
            animal.read!(:sex, r.sex, at: r.born_at) if animal.sex.blank?
            animal.read!(:healthy, true,  at: r.born_at)

            # load demo data weight and state
            if is_a_demo_instance
              weighted_at = r.born_at
              if weighted_at and weighted_at < Time.now
                variation = 0.02
                while (r.dead_at.nil? or weighted_at < r.dead_at) and weighted_at < Time.now
                  age = (weighted_at - r.born_at).to_f
                  weight = (age < 990 ? 700 * Math.sin(age / (100 * 2 * Math::PI)) + 50.0 : 750)
                  weight += rand(weight * variation * 2) - (weight * variation)
                  animal.read!(:net_mass, weight.in_kilogram.round(1), at: weighted_at)
                  weighted_at += (70 + rand(40)).days + 30.minutes - rand(60).minutes
                end
              end
              #animal.read!(:healthy, true,  at: (now - 3.days))
              #animal.read!(:healthy, false, at: (now - 2.days))
            end

            group.record.add(animal, r.arrived_on)
            group.record.remove(animal, r.departed_on) if r.departed_on

            w.check_point
          end
        end
      end
    end

    file = first_run.path("synel", "inventaire.csv")
    if file.exist?
      first_run.count :assign_parents_with_inventory do |w|
        # animals cache, for speeder mother / father search
        parents = { mother: {}, father: {} }
        CSV.foreach(file, encoding: "CP1252", col_sep: "\t", headers: false) do |row|

          born_on = (row[4].blank? ? nil : Date.parse(row[4]))
          incoming_on = (row[6].blank? ? nil : Date.parse(row[6]))
          outgoing_on = (row[12].blank? ? nil : Date.parse(row[12]))

          r = OpenStruct.new(:work_number => row[0],
                             :identification_number => (row[0] ? cattling_root_number+row[0].to_s : nil),
                             :name => (row[1].blank? ? Faker::Name.first_name+" (MN)" : row[1].capitalize),
                             :mother_variety_code => (row[13].blank? ? nil : row[13]),
                             :father_variety_code => (row[14].blank? ? nil : row[14]),
                             :sex => (row[3].blank? ? nil : (row[3] == "F" ? :female : :male)),
                             :born_on => born_on,
                             born_at: (born_on ? born_on.to_datetime + 10.hours : nil),
                             :incoming_cause => row[5],
                             :incoming_on => incoming_on,
                             incoming_at: (incoming_on ? incoming_on.to_datetime + 10.hours : nil),
                             :mother_identification_number => row[7],
                             :mother_work_number => (row[7] ? row[7][-4..-1] : nil),
                             :mother_name => (row[8].blank? ? Faker::Name.first_name : row[8].capitalize),
                             :father_identification_number => row[9],
                             :father_work_number => (row[9] ? row[9][-4..-1] : nil),
                             :father_name => (row[10].blank? ? Faker::Name.first_name : row[10].capitalize),
                             :outgoing_cause => row[11],
                             :outgoing_on => outgoing_on,
                             outgoing_at: (outgoing_on ? outgoing_on.to_datetime + 10.hours : nil)
                             )
          # check if animal is present in DB
          next unless animal = Animal.find_by(identification_number: r.identification_number)

          # Find mother
          unless r.mother_identification_number.blank? and Animal.find_by(identification_number: r.mother_identification_number)
            parents[:mother][r.mother_identification_number] ||= Animal.find_by(identification_number: r.mother_identification_number)
            link = animal.links.new(nature: :mother,  started_at: animal.born_at)
            link.linked = parents[:mother][r.mother_identification_number]
            link.save
          end

          # find a the father variety from field in file
            father_items = Nomen::Varieties.where(french_race_code: r.father_variety_code)
            if father_items
              father_bos_variety = father_items.first.name
            else
              father_bos_variety = "bos"
            end


          # Find or create father
          unless r.father_identification_number.blank?
            parents[:father][r.father_identification_number] ||=
              Animal.find_by(identification_number: r.father_identification_number) ||
              Animal.create!(:variant_id => male_adult_cow.id,
                             :name => r.father_name,
                             :variety => father_bos_variety,
                             :identification_number => r.father_identification_number,
                             work_number: r.father_work_number,
                             :initial_owner => owners.sample,
                             :initial_container => place,
                             :default_storage => place)
            link = animal.links.new(nature: :father,  started_at: animal.born_at)
            link.linked = parents[:father][r.father_identification_number]
            link.save
          end
          w.check_point
        end

      end
    end

    groups, male_adult_cow, female_adult_cow, place, owners, is_a_demo_instance, variants, owner = nil
    GC.start

    # attach picture if exist for each animal
    Animal.find_each do |animal|
      picture_path = first_run.path("alamano", "animals_pictures", "#{animal.work_number}.jpg")
      f = (picture_path.exist? ? File.open(picture_path) : nil)
      if f
        animal.update!(picture: f)
        f.close
      end
    end
  end
end
