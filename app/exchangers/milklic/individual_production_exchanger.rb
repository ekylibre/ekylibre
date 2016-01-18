class Milklic::IndividualProductionExchanger < ActiveExchanger::Base
  def import
    analyser_attributes = YAML.load_file(File.join(File.dirname(__FILE__), 'entity.yml'))

    unless analyser = Entity.find_by(siret_number: analyser_attributes[:siret_number])
      analyser = Entity.create!(analyser_attributes)
    end

    begin
      rows = CSV.read(file, encoding: 'CP1252', col_sep: ';', headers: true)
    rescue
      raise NotWellFormedFileError
    end
    w.count = rows.size

    rows.each_with_index do |row, _index|
      r = OpenStruct.new(animal_name: row[0],
                         animal_work_number: row[1],
                         animal_lactation_number: row[2],
                         animal_lactation_started_on: row[3]
                        )

      # if an animal exist
      if animal = Animal.find_by_work_number(r.animal_work_number)
        for i in 4..15
          next unless row[i] && row.headers[i]
          milk_daily_production_measure = row[i].tr(',', '.').to_d.in_kilogram_per_day
          milk_daily_production_at = Date.strptime(row.headers[i], '%d/%m/%y').to_time
          animal.read!(:milk_daily_production, milk_daily_production_measure, at: milk_daily_production_at, force: true) if milk_daily_production_measure && milk_daily_production_at
        end
      end
      w.check_point
    end
  end
end
