# Create or updates animal groups
Exchanges.add_importer :ekylibre_animal_groups do |file, w|

  rows = CSV.read(file, headers: true).delete_if{|r| r[0].blank?}
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

    w.check_point
  end

end
