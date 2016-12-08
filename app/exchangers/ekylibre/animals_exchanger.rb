module Ekylibre
  class AnimalsExchanger < ActiveExchanger::Base
    # Create or updates animals
    def import
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      rows.each do |row|
        r = OpenStruct.new(
          name: row[0],
          nature: row[1].to_sym,
          code: (row[2].blank? ? nil : row[2].to_s),
          place: (row[3].blank? ? nil : row[3].to_s),
          group: (row[4].blank? ? nil : row[4].to_s),
          born_at: (row[5].blank? ? Time.zone.today : row[5]).to_datetime,
          variety: (row[6].blank? ? nil : row[6].to_sym),
          initial_owner: (row[7].blank? ? nil : row[7].to_s),
          indicators: row[8].blank? ? {} : row[8].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each_with_object({}) do |i, h|
            h[i.first.strip.downcase.to_sym] = i.second
            h
          end,
          record: nil
        )

        unless animal = Animal.find_by(work_number: r.code)
          animal = Animal.create!(
            name: r.name,
            work_number: r.code,
            identification_number: r.code,
            initial_born_at: r.born_at,
            initial_population: 1.0,
            variant: ProductNatureVariant.import_from_nomenclature(r.nature),
            default_storage: BuildingDivision.find_by(work_number: r.place)
          )
          # create indicators linked to animal
          r.indicators.each do |indicator_name, value|
            next if indicator_name == :population
            animal.read!(indicator_name, value, at: r.born_at, force: true)
          end
          animal.initial_population = animal.population
          animal.variety = r.variety if r.variety
          if owner = Entity.find_by(full_name: r.initial_owner)
            animal.initial_owner = owner
          end
          if r.group && animal_group = AnimalGroup.find_by(work_number: r.group)
            animal.memberships.create!(group: animal_group, started_at: r.born_at, nature: :interior)
          end
          animal.save!
        end

        w.check_point
      end
    end
  end
end
