module Ekylibre
  class AnimalGroupsExchanger < ActiveExchanger::Base
    def check
      valid = true

      # Check building division presence
      unless building_division = BuildingDivision.first
        w.error 'Need almost one BuildingDivision'
        valid = false
      end

      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size
      rows.each_with_index do |row, index|
        line_number = index + 2
        prompt = "L#{line_number.to_s.yellow}"
        next if row[0].blank?
        r = OpenStruct.new(
          name: row[0],
          nature: row[1].to_s,
          member_nature: (row[2].blank? ? nil : row[2].to_sym),
          code: row[3],
          minimum_age: (row[4].blank? ? nil : row[4].to_i),
          maximum_age: (row[5].blank? ? nil : row[5].to_i),
          sex: (row[6].blank? ? nil : row[6].to_sym),
          place: (row[7].blank? ? nil : row[7].to_s),
          indicators_at: (row[8].blank? ? Time.zone.today : row[8]).to_datetime,
          indicators: row[9].blank? ? {} : row[9].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each_with_object({}) do |i, h|
            h[i.first.strip.downcase.to_sym] = i.second
            h
          end,
          activity_family_name: row[10].to_s,
          activity_name: row[11].to_s,
          campaign_year: row[12].to_i
        )

        unless variant = ProductNatureVariant.find_by_number(r.nature)
          unless variant = ProductNatureVariant.import_from_nomenclature(r.nature.to_sym)
            w.error "#{prompt} #{r.nature} does not exist in NOMENCLATURE or in DB"
            valid = false
          end
        end
        r.member_nature = "#{r.member_nature}_band".to_sym if r.member_nature.to_s =~ /^(fe)?male_young_pig$/
        r.member_nature = :young_rabbit if r.member_nature.to_s =~ /^(fe)?male_young_rabbit$/
        animal_variant = ProductNatureVariant.find_by(number: r.member_nature) ||
                         ProductNatureVariant.find_by(reference_name: r.member_nature) ||
                         ProductNatureVariant.import_from_nomenclature(r.member_nature)
        unless animal_variant
          w.error "#{prompt} #{r.member_nature} does not exist in NOMENCLATURE or in DB"
          valid = false
        end

        unless animal_container = Product.find_by_work_number(r.place)
          w.error "#{prompt} #{r.place} does not exist in DB"
          valid = false
        end

        next unless r.variant_reference_name
        next if variant = ProductNatureVariant.find_by(work_number: r.variant_reference_name)
        unless nomen = Nomen::ProductNatureVariant.find(r.variant_reference_name.downcase.to_sym)
          w.error "No variant exist in NOMENCLATURE for #{r.variant_reference_name.inspect}"
          valid = false
        end
      end
    end

    # Create or updates animal groups
    def import
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      rows.each do |row|
        r = OpenStruct.new(
          name: row[0],
          nature: row[1].to_s,
          member_nature: (row[2].blank? ? nil : row[2].to_sym),
          code: row[3],
          minimum_age: (row[4].blank? ? nil : row[4].to_i),
          maximum_age: (row[5].blank? ? nil : row[5].to_i),
          sex: (row[6].blank? ? nil : row[6].to_sym),
          place: (row[7].blank? ? nil : row[7].to_s),
          indicators_at: (row[8].blank? ? Time.zone.today : row[8]).to_datetime,
          indicators: row[9].blank? ? {} : row[9].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each_with_object({}) do |i, h|
            h[i.first.strip.downcase.to_sym] = i.second
            h
          end,
          activity_family_name: row[10].to_s,
          activity_name: row[11].to_s,
          campaign_year: row[12].to_i
        )

        unless variant = ProductNatureVariant.find_by_work_number(r.nature)
          variant = ProductNatureVariant.import_from_nomenclature(r.nature.to_sym)
        end

        r.member_nature = "#{r.member_nature}_band".to_sym if r.member_nature.to_s =~ /^(fe)?male_young_pig$/
        r.member_nature = :young_rabbit if r.member_nature.to_s =~ /^(fe)?male_young_rabbit$/
        animal_variant = ProductNatureVariant.find_by(work_number: r.member_nature) ||
                         ProductNatureVariant.find_by(reference_name: r.member_nature) ||
                         ProductNatureVariant.import_from_nomenclature(r.member_nature)
        unless animal_variant
          animal_variant = ProductNatureVariant.import_from_nomenclature(r.member_nature)
        end
        animal_container = Product.find_by_work_number(r.place)

        unless animal_group = AnimalGroup.find_by(work_number: r.code)
          animal_group = AnimalGroup.create!(
            name: r.name,
            work_number: r.code,
            initial_born_at: r.indicators_at,
            variant: variant,
            default_storage: BuildingDivision.find_by(work_number: r.place)
          )
          # create indicators linked to animal group
          r.indicators.each do |indicator, value|
            if indicator.to_sym == :population
              animal_group.move!(value, at: r.indicators_at)
            else
              animal_group.read!(indicator, value, at: r.indicators_at, force: true)
            end
          end
          # animal_group.initial_population = animal_group.population
          animal_group.save!
        end

        # Check if animals exist with given sex and age
        if r.minimum_age && r.maximum_age && r.sex
          max_born_at = Time.zone.now - r.minimum_age.days if r.minimum_age
          min_born_at = Time.zone.now - r.maximum_age.days if r.maximum_age
          animals = Animal.indicate(sex: r.sex.to_s).where(born_at: min_born_at..max_born_at).reorder(:name)
          # find support for intervention changing or create it
          unless ap = ActivityProduction.where(support_id: animal_group.id).first
            # campaign = Campaign.find_or_create_by!(harvest_year: r.campaign_year)
            family = Nomen::ActivityFamily.find(:animal_farming)
            r.activity_name = family.human_name if r.activity_name.blank?
            unless activity = Activity.find_by(name: r.activity_name)
              # family = Activity.find_best_family(animal_group.derivative_of, animal_group.variety)
              unless family
                w.error 'Cannot determine activity'
                raise ActiveExchanger::Error, "Cannot determine activity with support #{support_variant ? support_variant.variety.inspect : '?'} and cultivation #{cultivation_variant ? cultivation_variant.variety.inspect : '?'} in production #{sheet_name}"
              end
              activity = Activity.create!(
                name: r.activity_name,
                family: family.name,
                nature: family.nature,
                production_cycle: :perennial
              )
            end
            # get first harvest_year of first campaign
            first_year_of_campaign = Campaign.first_of_all.harvest_year if Campaign.first_of_all
            if animals.any?
              ap = ActivityProduction.create!(
                activity: activity,
                support_id: animal_group.id,
                size_value: animals.count,
                support_nature: :animal_group,
                started_on: first_year_of_campaign ? Date.civil(first_year_of_campaign, 1, 1) : Date.civil(1970, 1, 1),
                usage: :milk
              )
            end
          end
          # if animals and production_support, add animals to the target distribution
          if animals.any? && ap.present?
            animals.each do |animal|
              td = TargetDistribution.find_or_create_by!(activity: activity, activity_production: ap, target: animal)
            end
            # TODO: how to add animals to a group
            # animal_group.add_animals(animals, started_at: Time.zone.now - 1.hour, stopped_at: Time.zone.now, production_support_id: ps.id, container_id: animal_container.id, variant_id: animal_variant.id, worker_id: Worker.first.id)
          end
        end

        w.check_point
      end
    end

    # puts animals in a group by default
    def update_animal_evolution
      # TODO: change default variant of animal if needed
    end

    # puts animals in a place by default
    def update_animal_place
      # TODO: change default place of animal if needed
    end
  end
end
