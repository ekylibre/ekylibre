class FIEA::GalacteaExchanger < ActiveExchanger::Base
  def import
    unless analyser = Entity.where('LOWER(full_name) LIKE ?', '%Atlantic Conseil Elevage%'.mb_chars.downcase).first
      analyser = Entity.create!(last_name: 'Atlantic Conseil Elevage',
                                nature: :organization,
                                vat_number: 'FR00123456789',
                                supplier: true, client: false,
                                mails_attributes: {
                                  0 => {
                                    canal: 'mail',
                                    mail_line_4: 'CS 10015 - Les Rochettes',
                                    mail_line_6: '85036 La Roche-sur-Yon',
                                    mail_country: :fr
                                  }
                                },
                                emails_attributes: {
                                  0 => {
                                    canal: 'email',
                                    coordinate: 'accueil@atlantic-conseil-elevage.fr'
                                  }
                                })
    end

    # @TODO need a method for each file in a folder like first_run.glob('lca/*.csv') do |file|

    # # import Milk result to make automatic quality indicators
    # product_nature_variant = ProductNatureVariant.import_from_nomenclature(:cow_milk)

    trans_animal_state = {
      'M' => :bad,
      'S' => :good,
      'D' => :bad
    }

    rows = CSV.read(file, col_sep: "\t", headers: true)
    w.count = rows.size

    rows.each do |row|
      r = OpenStruct.new(at: (row[0].blank? ? nil : Date.civil(*row[0].to_s.split(/\//).reverse.map(&:to_i))),
                         reference_number: row[1].to_s + '-L' + row[5].to_s + '-C' + row[6].to_s,
                         animal_work_number: row[4].to_s,
                         lactation_number: row[5].to_s,
                         control_number: row[6].to_s,
                         milk_daily_production: row[7].blank? ? nil : row[7].tr(',', '.').to_d.in_kilogram_per_day,
                         tb_daily_production: row[9].blank? ? nil : row[9].tr(',', '.').to_d.in_gram_per_liter,
                         tp_daily_production: row[10].blank? ? nil : row[10].tr(',', '.').to_d.in_gram_per_liter,
                         animal_state: (row[11].blank? ? nil : trans_animal_state[row[11].to_s]),
                         somatic_cell_concentration: row[12].blank? ? nil : row[12].to_i.in_thousand_per_milliliter,
                         calving_date: (row[13].blank? ? nil : Date.civil(*row[0].to_s.split(/\//).reverse.map(&:to_i))),
                         day_from_calving_date: row[14],
                         milk_production_from_calving_date: row[15],
                         tb_average_production: row[16],
                         tp_average_production: row[17],
                         standard_milk_production_from_calving_date: row[18])

      unless analysis = Analysis.where(reference_number: r.reference_number, analyser: analyser).first
        analysis = Analysis.create!(reference_number: r.reference_number, nature: 'unitary_cow_milk_analysis',
                                    analyser: analyser, sampled_at: r.at, analysed_at: r.at)

        analysis.read!(:fat_matters_concentration, r.tb_daily_production) unless r.tb_daily_production.nil?
        analysis.read!(:protein_matters_concentration, r.tp_daily_production) unless r.tp_daily_production.nil?
        analysis.read!(:somatic_cell_concentration, r.somatic_cell_concentration) unless r.somatic_cell_concentration.nil?
        analysis.read!(:healthy, r.animal_state) unless r.animal_state.nil?
        analysis.read!(:milk_daily_production, r.milk_daily_production) unless r.milk_daily_production.nil?

      end
      # if an animal exist , link to analysis
      if animal = Animal.find_by_work_number(r.animal_work_number)
        analysis.product = animal
        analysis.save!
        animal.read!(:healthy, true, at: r.at, force: true) if r.animal_state == :good
        animal.read!(:healthy, false, at: r.at, force: true) if r.animal_state == :bad
      end

      w.check_point
    end
  end
end
