module LelyMilkRobot
  class IndividualProductionExchanger < ActiveExchanger::Base
    category :animal_farming
    vendor :lely_milk_robot

    def import
      analyser_attributes = YAML.load_file(File.join(File.dirname(__FILE__), 'entity.yml'))

      unless analyser = Entity.find_by(siret_number: analyser_attributes[:siret_number])
        analyser = Entity.create!(analyser_attributes)
      end

      cattling_number = Identifier.find_by(nature: :cattling_number).value if Identifier.find_by(nature: :cattling_number)

      begin
        rows = CSV.read(file, encoding: 'UTF-8', col_sep: ';', headers: true)
      rescue
        raise NotWellFormedFileError
      end
      w.count = rows.size

      rows.each_with_index do |row, _index|
        r = OpenStruct.new(
          animal_work_number: row[0],
          analysed_on: (row[3].present? ? Date.parse(row[3].to_s) : nil),
          milk_daily_production: (row[4].present? ? row[4].tr(',', '.').to_d : nil),
          daily_weight: (row[5].present? ? row[5].tr(',', '.').to_d : nil)
        )

        next unless r.animal_work_number && r.milk_daily_production && r.daily_weight

        # if an animal exist
        if animal = Animal.find_by(work_number: r.animal_work_number)
          # for milk
          milk_daily_production_measure = r.milk_daily_production.in_kilogram_per_day
          # for daily_weight
          daily_weight_measure = r.daily_weight.in_kilogram
          milk_daily_production_at = r.analysed_on.to_time
          reference_number = 'LELY-' + r.analysed_on.to_s + '-DAILY-' + r.animal_work_number
          # analysis
          unless analysis = Analysis.where(reference_number: reference_number, analyser: analyser).first
            analysis = Analysis.create!(reference_number: reference_number, nature: 'unitary_cow_milk_analysis',
                                        analyser: analyser, sampled_at: milk_daily_production_at, analysed_at: milk_daily_production_at)
            analysis.read!(:milk_daily_production, milk_daily_production_measure)
            analysis.read!(:net_mass, daily_weight_measure)
            analysis.product = animal
            analysis.save!
          end
          # indicators on animal
          animal.read!(:milk_daily_production, milk_daily_production_measure, at: milk_daily_production_at, force: true)
          animal.read!(:net_mass, daily_weight_measure, at: milk_daily_production_at, force: true)
        end
        w.check_point
      end
    end
  end
end
