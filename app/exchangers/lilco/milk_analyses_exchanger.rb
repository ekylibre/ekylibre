class Lilco::MilkAnalysesExchanger < ActiveExchanger::Base
  def import
    analyser_attributes = YAML.load_file(File.join(File.dirname(__FILE__), 'entity.yml'))

    unless analyser = Entity.find_by(siret: analyser_attributes[:siret])
      analyser = Entity.create!(analyser_attributes)
    end

    begin
      rows = CSV.read(file, encoding: 'CP1252', col_sep: "\t", headers: true)
    rescue
      raise NotWellFormedFileError
    end
    w.count = rows.size

    trans_inhib = {
      'NEG' => 'negative',
      'POS' => 'positive'
    }

    rows.each do |row|
      r = OpenStruct.new(year: row[0],
                         month: row[1],
                         order: row[2],
                         reference_number: (row[0].to_s + row[1].to_s.rjust(2, '0') + row[2].to_s.rjust(2, '0')),
                         at: Date.civil(row[0].to_i, row[1].to_i, row[2].to_i * 9),
                         germes: (row[3].blank? ? 0 : row[3].to_i).in_thousand_per_milliliter,
                         inhib: trans_inhib[row[4]] || 'negative',
                         mg: (row[5].blank? ? 0 : (row[5].to_d) / 100).in_gram_per_liter,
                         mp: (row[6].blank? ? 0 : (row[6].to_d) / 100).in_gram_per_liter,
                         cells: (row[7].blank? ? 0 : row[7].to_i).in_thousand_per_milliliter,
                         buty: (row[8].blank? ? 0 : row[8].tr(',', '.').to_i).in_unity_per_liter,
                         cryo: (row[9].blank? ? 0 : row[9].tr(',', '.').to_d).in_celsius,
                         lipo: (row[10].blank? ? 0 : row[10].tr(',', '.').to_d).in_thousand_per_hectogram,
                         igg: (row[11].blank? ? 0 : row[11].to_d).in_unity_per_liter,
                         uree: (row[12].blank? ? 0 : row[12].to_i).in_milligram_per_liter,
                         salmon: row[13],
                         listeria: row[14],
                         staph: row[15],
                         coli: row[16],
                         pseudo: row[17],
                         ecoli: row[18]
                        )

      unless analysis = Analysis.where(reference_number: r.reference_number, analyser: analyser).first
        analysis = Analysis.create!(reference_number: r.reference_number,
                                    nature: 'cow_milk_analysis',
                                    analyser: analyser,
                                    analysed_at: r.at,
                                    sampled_at: r.at
                                   )

        analysis.read!(:total_bacteria_concentration, r.germes) if r.germes.to_f > 0
        analysis.read!(:inhibitors_presence, r.inhib)
        analysis.read!(:fat_matters_concentration, r.mg) if r.mg.to_f > 0
        analysis.read!(:protein_matters_concentration, r.mp) if r.mp.to_f > 0
        analysis.read!(:somatic_cell_concentration, r.cells) if r.cells.to_f > 0
        analysis.read!(:clostridial_spores_concentration, r.buty) if r.buty.to_f > 0
        analysis.read!(:freezing_point_temperature, r.cryo) if r.cryo.to_f > 0
        analysis.read!(:lipolysis, r.lipo) if r.lipo.to_f > 0
        analysis.read!(:immunoglobulins_concentration, r.igg) if r.igg.to_f > 0
        analysis.read!(:urea_concentration, r.uree) if r.uree.to_f > 0

      end

      w.check_point
    end
  end
end
