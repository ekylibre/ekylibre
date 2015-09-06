class Ekylibre::AnimalGroupsExchanger < ActiveExchanger::Base
  # Create or updates animal groups
  def import
    rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
    w.count = rows.size

    rows.each do |row|
      r = OpenStruct.new(name: row[0],
                         nature: row[1].to_sym,
                         member_nature: (row[2].blank? ? nil : row[2].to_sym),
                         code: row[3],
                         minimum_age: (row[4].blank? ? nil : row[4].to_i),
                         maximum_age: (row[5].blank? ? nil : row[5].to_i),
                         sex: (row[6].blank? ? nil : row[6].to_sym),
                         place: (row[7].blank? ? nil : row[7].to_sym),
                         indicators_at: (row[8].blank? ? (Date.today) : row[8]).to_datetime,
                         indicators: row[9].blank? ? {} : row[9].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.inject({}) do |h, i|
                           h[i.first.strip.downcase.to_sym] = i.second
                           h
                         end,
                         activity_name: row[10].to_s,
                         production_name: row[11].to_s,
                         campaign_year: row[12].to_i
                        )

      unless animal_group = AnimalGroup.find_by(work_number: r.code)
        animal_group = AnimalGroup.create!(name: r.name,
                                       work_number: r.code,
                                       initial_born_at: r.indicators_at,
                                       variant: ProductNatureVariant.import_from_nomenclature(r.nature),
                                       default_storage: BuildingDivision.find_by(work_number: r.place)
                                      )
        # create indicators linked to equipment
        for indicator, value in r.indicators
          animal_group.read!(indicator, value, at: r.indicators_at, force: true)
        end
        animal_group.initial_population = animal_group.population
        animal_group.save!
      end

      # Check if animals exist with given sex and age
      if r.minimum_age && r.maximum_age && r.sex
        max_born_at = Time.now - r.minimum_age.days if r.minimum_age
        min_born_at = Time.now - r.maximum_age.days if r.maximum_age
        animals = Animal.indicate(sex: r.sex.to_s).where(born_at: min_born_at..max_born_at).reorder(:name)
        # find support for intervention changing or create it
        unless ps = ProductionSupport.where(storage_id: animal_group.id).first
          campaign = Campaign.find_or_create_by!(harvest_year: r.campaign_year)
          unless activity = Activity.find_by(name: r.activity_name)
            family = Activity.find_best_family( animal_group.derivative_of, animal_group.variety)
            unless family
              w.error 'Cannot determine activity'
              fail ActiveExchanger::Error, "Cannot determine activity with support #{support_variant ? support_variant.variety.inspect : '?'} and cultivation #{cultivation_variant ? cultivation_variant.variety.inspect : '?'} in production #{sheet_name}"
            end
            activity = Activity.create!(name: r.activity_name, family: family.name, nature: family.nature)
          end
          unless p = Production.of_campaign(campaign).of_activities(activity).where(name: r.production_name, support_variant_id: animal_group.variant_id).first
            p = Production.create!(activity: activity, campaign: campaign, name: r.production_name, support_variant_id: animal_group.variant_id, cultivation_variant_id: animals.first.variant_id) if animals.count > 0
          end
          ps = p.supports.create!(storage_id: animal_group.id) if p
        end
        # if animals and production_support, add animals to the group
        if animals.count > 0 && ps.present?
          animal_group.add_animals(animals, started_at: Time.now - 1.hours, stopped_at: Time.now, production_support_id: ps.id)
        end
      end

      w.check_point
    end
  end

  # puts animals in a group by default
  def update_animal_evolution()
   #TODO change default variant of animal if needed
  end

  # puts animals in a place by default
  def update_animal_place()
    #TODO change default place of animal if needed
  end

end
