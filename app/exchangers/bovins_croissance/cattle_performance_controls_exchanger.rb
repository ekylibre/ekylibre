class BovinsCroissance::CattlePerformanceControlsExchanger < ActiveExchanger::Base
  def import
    rows = CSV.read(file,  encoding: 'CP1252', col_sep: "\t", headers: true)
    w.count = rows.size

    rows.each do |row|
      r = OpenStruct.new(animal_weight_at_birth: (row[13].blank? ? nil : row[13].to_d).in_kilogram,
                         animal_work_number: row[18].to_s,
                         first_weighting_at: (row[52].blank? ? nil : Date.civil(*row[52].to_s.split(/\//).reverse.map(&:to_i))),
                         first_weighting_value: row[53].blank? ? nil : (row[53].to_d).in_kilogram,
                         second_weighting_at: (row[55].blank? ? nil : Date.civil(*row[55].to_s.split(/\//).reverse.map(&:to_i))),
                         second_weighting_value: row[56].blank? ? nil : (row[56].to_d).in_kilogram,
                         third_weighting_at: (row[58].blank? ? nil : Date.civil(*row[58].to_s.split(/\//).reverse.map(&:to_i))),
                         third_weighting_value: row[59].blank? ? nil : (row[59].to_d).in_kilogram,
                         fourth_weighting_at: (row[61].blank? ? nil : Date.civil(*row[61].to_s.split(/\//).reverse.map(&:to_i))),
                         fourth_weighting_value: row[62].blank? ? nil : (row[62].to_d).in_kilogram
                        )
      # if an animal exist , link to weight
      if animal = Animal.find_by_work_number(r.animal_work_number)
        animal.read!(:net_mass, r.animal_weight_at_birth,  at: animal.born_at, force: true) if r.animal_weight_at_birth
        animal.read!(:net_mass, r.first_weighting_value,  at: r.first_weighting_at, force: true) if r.first_weighting_at
        animal.read!(:net_mass, r.second_weighting_value,  at: r.second_weighting_at, force: true) if r.second_weighting_at
        animal.read!(:net_mass, r.third_weighting_value,  at: r.third_weighting_at, force: true) if r.third_weighting_at
        animal.read!(:net_mass, r.fourth_weighting_value,  at: r.fourth_weighting_at, force: true) if r.fourth_weighting_at
      end

      w.check_point
    end
  end
end
