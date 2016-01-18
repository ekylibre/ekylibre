class AgroSystemes::WaterAnalysesExchanger < ActiveExchanger::Base
  def import
    here = Pathname.new(__FILE__).dirname
    analyser_attributes = YAML.load_file(here.join('entity.yml'))

    unless analyser = Entity.find_by(siret_number: analyser_attributes[:siret_number])
      analyser = Entity.create!(analyser_attributes)
    end

    begin
      rows = CSV.read(file, encoding: 'CP1252', col_sep: "\t", headers: true)
    rescue
      raise NotWellFormedFileError
    end
    w.count = rows.size

    rows.each do |row|
      r = OpenStruct.new(code_distri: (row[0].blank? ? nil : row[0].to_s),
                         reference_number: row[6].to_s,
                         at: (row[7].blank? ? nil : Date.civil(*row[7].to_s.split(/\//).reverse.map(&:to_i))),
                         water_work_number: row[8].blank? ? nil : landparcels_transcode[row[8]],
                         potential_hydrogen: row[9].blank? ? nil : row[9].to_d,
                         nitrogen_concentration: row[10].blank? ? nil : row[10].to_d.in_percent,
                         sampled_at: (row[12].blank? ? nil : Date.civil(*row[12].to_s.split(/\//).reverse.map(&:to_i))),
                         geolocation: (row[13].blank? ? nil : row[13].to_s)
                        )

      unless analysis = Analysis.where(reference_number: r.reference_number, analyser: analyser).first
        analysis = Analysis.create!(reference_number: r.reference_number, nature: 'water_analysis',
                                    analyser: analyser, sampled_at: r.sampled_at, analysed_at: r.at
                                   )

        analysis.read!(:potential_hydrogen, r.potential_hydrogen) if r.potential_hydrogen
        analysis.read!(:nitrogen_concentration, r.nitrogen_concentration) if r.nitrogen_concentration
      end

      # if an lan_parcel exist, link to analysis
      if water = Matter.of_variety('water')
        analysis.product = water
        analysis.save!
        water.read!(:potential_hydrogen, r.potential_hydrogen, at: r.sampled_at) if r.potential_hydrogen
        water.read!(:nitrogen_concentration, r.nitrogen_concentration, at: r.sampled_at) if r.nitrogen_concentration
      end

      # if a georeading exist, link to analysis
      if georeading = Georeading.find_by(number: r.geolocation)
        analysis.geolocation = georeading.content
        analysis.save!
      end

      w.check_point
    end
  end
end
